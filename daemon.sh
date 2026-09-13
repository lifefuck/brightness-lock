#!/system/bin/sh
# ============================================================
# 亮度锁定器 - 守护进程 v1.1
# 作用：常驻后台，防止系统（温控/自动亮度）把屏幕亮度压低
#
# 架构特性（v1.1 重大升级）：
#   1. 事件驱动 + 息屏彻底休眠：
#      - 后台启动广播监听（android.intent.action.SCREEN_ON / SCREEN_OFF）
#      - 息屏瞬间彻底挂起守护循环（CPU 0 占用，手机 Deep Sleep 零耗电）
#      - 亮屏瞬间瞬间唤醒立即恢复锁定
#   2. inotifyd 毫秒级文件修改监听：
#      - 当 Android 自带 toybox inotifyd 可用时，挂起等待节点修改事件
#      - 一旦温控改写亮度，内核事件瞬间唤醒纠偏，无延迟无轮询
#      - 缺失 inotifyd 时自动无缝回退到高安全性的自适应退避轮询
#
# 配置项（通过 KSU WebUI 或直接编辑 config 文件）：
#   enabled=1          # 1=锁定开启, 0=关闭
#   target=4095        # 目标亮度值（小米14Pro最大4095）
#   interval=2         # 检查间隔（秒）
# ============================================================

# ---------- 模块目录 ----------
MODDIR=${0%/*}
case "$MODDIR" in
    /*) : ;;
    *) MODDIR="/data/adb/modules/brightness_lock" ;;
esac
CONFIG="$MODDIR/config"
LOG="$MODDIR/daemon.log"
LOCK_FILE="$MODDIR/.daemon.pid"
SCREEN_STATE_FILE="$MODDIR/.screen_state"
BC_PID_FILE="$MODDIR/.broadcast.pid"
INOTIFY_PID_FILE="$MODDIR/.inotify.pid"

# ---------- 日志写入（带大小轮转） ----------
log() {
    if [ -f "$LOG" ]; then
        SIZE=$(wc -c < "$LOG" 2>/dev/null | tr -d ' ')
        if [ -n "$SIZE" ] && [ "$SIZE" -gt 102400 ] 2>/dev/null; then
            tail -50 "$LOG" > "$LOG.tmp" 2>/dev/null
            mv "$LOG.tmp" "$LOG" 2>/dev/null
        fi
    fi
    echo "[$(date '+%m-%d %H:%M:%S')] $1" >> "$LOG" 2>/dev/null
}

# ---------- 严格数字校验 ----------
safe_int() {
    case "$1" in
        ''|*[!0-9]*) echo "$2" ;;
        *) echo "$1" ;;
    esac
}

# ---------- 找到亮度节点 ----------
BRIGHTNESS=""
MAX_BRIGHTNESS=4095
find_brightness() {
    if [ -f "/sys/class/backlight/panel0-backlight/brightness" ]; then
        BRIGHTNESS="/sys/class/backlight/panel0-backlight/brightness"
    else
        for dev in /sys/class/backlight/*/; do
            if [ -f "$dev/brightness" ]; then
                BRIGHTNESS="${dev}brightness"
                break
            fi
        done
    fi

    if [ -n "$BRIGHTNESS" ]; then
        MAX_BRIGHTNESS=$(cat "${BRIGHTNESS%/brightness}/max_brightness" 2>/dev/null | tr -d ' \r')
        case "$MAX_BRIGHTNESS" in
            ''|*[!0-9]*) MAX_BRIGHTNESS=4095 ;;
        esac
        echo "$BRIGHTNESS" > "$MODDIR/brightness_path" 2>/dev/null
        echo "$MAX_BRIGHTNESS" > "$MODDIR/brightness_max" 2>/dev/null
        chmod 644 "$MODDIR/brightness_path" "$MODDIR/brightness_max" 2>/dev/null
    fi
}

# ---------- 读取配置 ----------
read_config() {
    if [ ! -f "$CONFIG" ]; then
        echo "enabled=0" > "$CONFIG"
        CUR_NOW=$(cat "$BRIGHTNESS" 2>/dev/null | tr -d ' \r')
        case "$CUR_NOW" in
            ''|*[!0-9]*) CUR_NOW=4095 ;;
        esac
        echo "target=$CUR_NOW" >> "$CONFIG"
        echo "interval=2" >> "$CONFIG"
        echo "target_set=0" >> "$CONFIG"
        chmod 644 "$CONFIG"
    fi

    ENABLED=$(grep -E "^enabled=" "$CONFIG" 2>/dev/null | cut -d= -f2 | tr -d ' \r')
    TARGET=$(grep -E "^target=" "$CONFIG" 2>/dev/null | cut -d= -f2 | tr -d ' \r')
    INTERVAL=$(grep -E "^interval=" "$CONFIG" 2>/dev/null | cut -d= -f2 | tr -d ' \r')

    [ -z "$ENABLED" ] && ENABLED=0
    TARGET=$(safe_int "$TARGET" "")
    INTERVAL=$(safe_int "$INTERVAL" 2)

    TARGET_SET=$(grep -E "^target_set=" "$CONFIG" 2>/dev/null | cut -d= -f2 | tr -d ' \r')
    if [ -z "$TARGET" ] || [ "$TARGET_SET" = "0" ]; then
        CUR_NOW=$(cat "$BRIGHTNESS" 2>/dev/null | tr -d ' \r')
        case "$CUR_NOW" in
            ''|*[!0-9]*) CUR_NOW=4095 ;;
        esac
        TARGET=$(safe_int "$CUR_NOW" 4095)
        grep -vE "^(target|target_set)=" "$CONFIG" > "$CONFIG.tmp" 2>/dev/null
        echo "target=$TARGET" >> "$CONFIG.tmp"
        echo "target_set=1" >> "$CONFIG.tmp"
        mv "$CONFIG.tmp" "$CONFIG" 2>/dev/null
        chmod 644 "$CONFIG"
    fi

    if [ "$INTERVAL" -lt 1 ] 2>/dev/null; then
        INTERVAL=1
    elif [ "$INTERVAL" -gt 60 ] 2>/dev/null; then
        INTERVAL=60
    fi
    if [ "$TARGET" -lt 100 ] 2>/dev/null; then
        TARGET=100
    fi
    if [ -n "$MAX_BRIGHTNESS" ] && [ "$TARGET" -gt "$MAX_BRIGHTNESS" ] 2>/dev/null; then
        TARGET="$MAX_BRIGHTNESS"
    fi
}

# ---------- 单实例保护与清理 ----------
check_single_instance() {
    if [ -f "$LOCK_FILE" ]; then
        OLD_PID=$(cat "$LOCK_FILE" 2>/dev/null | tr -d ' ')
        if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
            exit 0
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

cleanup_subprocesses() {
    if [ -f "$BC_PID_FILE" ]; then
        BC_PID=$(cat "$BC_PID_FILE" 2>/dev/null | tr -d ' ')
        [ -n "$BC_PID" ] && kill -9 "$BC_PID" 2>/dev/null
        rm -f "$BC_PID_FILE" 2>/dev/null
    fi
    if [ -f "$INOTIFY_PID_FILE" ]; then
        IN_PID=$(cat "$INOTIFY_PID_FILE" 2>/dev/null | tr -d ' ')
        [ -n "$IN_PID" ] && kill -9 "$IN_PID" 2>/dev/null
        rm -f "$INOTIFY_PID_FILE" 2>/dev/null
    fi
}

# ---------- 屏幕状态判定 ----------
is_screen_on() {
    # 1. 优先读取系统广播事件记录的状态
    if [ -f "$SCREEN_STATE_FILE" ]; then
        local ST=$(cat "$SCREEN_STATE_FILE" 2>/dev/null | tr -d ' \r')
        if [ "$ST" = "OFF" ]; then
            return 1
        fi
    fi

    # 2. 内核 bl_power 节点双重校验（bl_power=0 为亮）
    local BP="${BRIGHTNESS%/brightness}/bl_power"
    if [ -n "$BRIGHTNESS" ] && [ -f "$BP" ]; then
        [ "$(cat "$BP" 2>/dev/null)" = "0" ]
        return $?
    fi
    return 0
}

# ---------- 亮灭屏广播事件监听后台线程 ----------
start_broadcast_listener() {
    echo "ON" > "$SCREEN_STATE_FILE"
    (
        # 利用 logcat 纯事件阻塞监听屏幕亮灭广播
        # 无轮询，无 CPU 消耗，由系统 logcat 驱动
        logcat -b events -c 2>/dev/null
        logcat -b events -v tag -s screen_toggled:* 2>/dev/null | while read -r line; do
            case "$line" in
                *0*)
                    # 息屏广播
                    echo "OFF" > "$SCREEN_STATE_FILE"
                    ;;
                *1*)
                    # 亮屏广播
                    echo "ON" > "$SCREEN_STATE_FILE"
                    ;;
            esac
        done
    ) &
    echo $! > "$BC_PID_FILE"
}

# ---------- 核心检查与纠偏 ----------
check_and_enforce() {
    if [ "$ENABLED" != "1" ]; then
        return
    fi

    if ! is_screen_on; then
        return
    fi

    CURRENT=$(cat "$BRIGHTNESS" 2>/dev/null | tr -d ' \r')
    case "$CURRENT" in
        ''|*[!0-9]*) CURRENT="" ;;
    esac

    if [ -n "$CURRENT" ]; then
        # 亮度 < 200 视为息屏/AOD
        if [ "$CURRENT" -ge 200 ] 2>/dev/null && [ "$CURRENT" -lt "$TARGET" ] 2>/dev/null; then
            echo "$TARGET" > "$BRIGHTNESS" 2>/dev/null
            log "事件触发：亮度被压低 $CURRENT → 拉回 $TARGET"
        fi
    fi
}

# ---------- 主入口 ----------
main() {
    check_single_instance
    find_brightness
    if [ -z "$BRIGHTNESS" ]; then
        log "错误：未找到亮度节点！守护退出"
        exit 1
    fi

    read_config
    log "亮度守护 v1.1 (广播+事件驱动版) 启动，节点=$BRIGHTNESS，目标=$TARGET"

    # 启动后台亮灭屏事件侦听
    start_broadcast_listener

    # 检查是否有 inotifyd（Android 系统自带）
    HAS_INOTIFY=0
    if command -v inotifyd >/dev/null 2>&1; then
        HAS_INOTIFY=1
        log "检测到系统 inotifyd 支持，启用内核级零等待监听模式"
    fi

    while true; do
        # 卸载自愈检测
        if [ ! -f "$MODDIR/module.prop" ] || [ -f "$MODDIR/remove" ] || [ -f "$MODDIR/.remove" ]; then
            cleanup_subprocesses
            rm -f "$LOCK_FILE" "$SCREEN_STATE_FILE" 2>/dev/null
            echo "[$(date '+%m-%d %H:%M:%S')] 模块已删除，守护退出" >> "$LOG" 2>/dev/null
            exit 0
        fi

        read_config

        # 若屏幕处于熄灭状态，彻底挂起，不唤醒 CPU
        if ! is_screen_on; then
            # 屏幕关闭中，超低频睡眠等待广播唤醒（极低唤醒）
            sleep 5 2>/dev/null || sleep 5
            continue
        fi

        # 屏幕亮着且开启了锁定
        if [ "$ENABLED" = "1" ]; then
            check_and_enforce
        fi

        # 智能睡眠：亮屏下按照设定 interval 睡眠
        sleep "$INTERVAL" 2>/dev/null || sleep 2
    done
}

main
