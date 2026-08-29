#!/system/bin/sh
# ============================================================
# 亮度锁定器 - 守护进程 v1.1
# 作用：常驻后台，防止系统（温控/自动亮度）把屏幕亮度压低
#
# 工作原理：
#   1. 每 N 秒检查一次锁定开关（模块目录 config 文件）
#   2. 开关开启时，检查屏幕是否亮着（bl_power=0 表示亮）
#   3. 如果亮度被系统压低到目标值以下，立即拉回目标值
#
# v1.1 修复（安全性审查后）：
#   [严重] 配置解析运算符优先级 bug → 非法 interval 导致 sleep 空转刷 CPU
#   [严重] 日志无限增长 → 限制日志 100KB 自动轮转
#   [严重] AOD 息屏显示时误拉满亮度 → 亮度 < 200 视为息屏/AOD 不干预
#   [中等] 多实例重复启动 → 启动前检测已有实例
#   [中等] CURRENT 非数字比较异常 → 严格数字校验
#
# 配置项（通过 KSU WebUI 或直接编辑 config 文件）：
#   enabled=1          # 1=锁定开启, 0=关闭
#   target=4095        # 目标亮度值（小米14Pro最大4095）
#   interval=2         # 检查间隔（秒）
# ============================================================

# ---------- 模块目录（不依赖 $0，防止相对路径启动导致错误） ----------
# ${0%/*} 在绝对路径启动时正确；相对路径启动时会得到 "." 或 "daemon.sh"
# 因此兜底使用 KSU 标准挂载路径（模块 id 固定为 brightness_lock）
MODDIR=${0%/*}
case "$MODDIR" in
    /*) : ;;  # 绝对路径，正常
    *) MODDIR="/data/adb/modules/brightness_lock" ;;  # 相对路径，用标准路径
esac
CONFIG="$MODDIR/config"
LOG="$MODDIR/daemon.log"
LOCK_FILE="$MODDIR/.daemon.pid"

# ---------- 日志写入（带大小轮转） ----------
log() {
    # 日志超过 100KB 时轮转（保留最近内容）
    if [ -f "$LOG" ]; then
        # wc -c 输出可能带前导空格，清洗后再比较
        SIZE=$(wc -c < "$LOG" 2>/dev/null | tr -d ' ')
        if [ -n "$SIZE" ] && [ "$SIZE" -gt 102400 ] 2>/dev/null; then
            # 保留最后 50 行，其余丢弃
            tail -50 "$LOG" > "$LOG.tmp" 2>/dev/null
            mv "$LOG.tmp" "$LOG" 2>/dev/null
        fi
    fi
    echo "[$(date '+%m-%d %H:%M:%S')] $1" >> "$LOG" 2>/dev/null
}

# ---------- 严格数字校验 ----------
# 输入非法返回默认值
safe_int() {
    case "$1" in
        ''|*[!0-9]*) echo "$2" ;;   # 非纯数字 → 返回默认值
        *) echo "$1" ;;
    esac
}

# ---------- 读取配置（带默认值 + 严格校验） ----------
read_config() {
    # 配置不存在时创建默认配置
    if [ ! -f "$CONFIG" ]; then
        echo "enabled=1" > "$CONFIG"
        echo "target=4095" >> "$CONFIG"
        echo "interval=2" >> "$CONFIG"
        chmod 644 "$CONFIG"
    fi

    # 解析配置（去掉可能的 \r 和空格）
    ENABLED=$(grep -E "^enabled=" "$CONFIG" 2>/dev/null | cut -d= -f2 | tr -d ' \r')
    TARGET=$(grep -E "^target=" "$CONFIG" 2>/dev/null | cut -d= -f2 | tr -d ' \r')
    INTERVAL=$(grep -E "^interval=" "$CONFIG" 2>/dev/null | cut -d= -f2 | tr -d ' \r')

    # 默认值兜底（严格数字校验，杜绝非法值）
    [ -z "$ENABLED" ] && ENABLED=1
    TARGET=$(safe_int "$TARGET" 4095)
    INTERVAL=$(safe_int "$INTERVAL" 2)

    # 边界限制：interval 至少 1 秒，最多 60 秒
    if [ "$INTERVAL" -lt 1 ] 2>/dev/null; then
        INTERVAL=1
    elif [ "$INTERVAL" -gt 60 ] 2>/dev/null; then
        INTERVAL=60
    fi
    # target 至少 100，防止写坏
    if [ "$TARGET" -lt 100 ] 2>/dev/null; then
        TARGET=100
    fi
}

# ---------- 单实例保护 ----------
check_single_instance() {
    # 通过 pid 文件判断是否已有实例在跑
    if [ -f "$LOCK_FILE" ]; then
        OLD_PID=$(cat "$LOCK_FILE" 2>/dev/null | tr -d ' ')
        if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
            # 已有实例在运行，本实例退出
            exit 0
        fi
    fi
    # 写入当前 PID
    echo $$ > "$LOCK_FILE"
}

# ---------- 找到亮度节点 ----------
BRIGHTNESS=""
find_brightness() {
    # 标准路径（小米14Pro实测）
    if [ -f "/sys/class/backlight/panel0-backlight/brightness" ]; then
        BRIGHTNESS="/sys/class/backlight/panel0-backlight/brightness"
        return
    fi
    # 遍历所有 backlight 设备
    for dev in /sys/class/backlight/*/; do
        if [ -f "$dev/brightness" ]; then
            BRIGHTNESS="${dev}brightness"
            return
        fi
    done
}

# ---------- 检查屏幕是否亮着 ----------
is_screen_on() {
    # bl_power=0 表示亮；没有 bl_power 就默认亮
    local BP="/sys/class/backlight/panel0-backlight/bl_power"
    if [ -f "$BP" ]; then
        [ "$(cat "$BP" 2>/dev/null)" = "0" ]
        return $?
    fi
    return 0
}

# ---------- 主循环 ----------
main() {
    # 单实例保护
    check_single_instance

    # 查找亮度节点
    find_brightness
    if [ -z "$BRIGHTNESS" ]; then
        log "错误：未找到亮度节点！守护退出"
        exit 1
    fi

    log "亮度守护启动，节点=$BRIGHTNESS，目标=4095，间隔=2s"

    while true; do
        # 重新读取配置（WebUI 修改实时生效）
        read_config

        if [ "$ENABLED" = "1" ]; then
            # 屏幕亮着才干预
            if is_screen_on; then
                CURRENT=$(cat "$BRIGHTNESS" 2>/dev/null | tr -d ' \r')

                # 严格数字校验：CURRENT 必须是纯数字才处理
                case "$CURRENT" in
                    ''|*[!0-9]*) CURRENT="" ;;
                esac

                if [ -n "$CURRENT" ]; then
                    # 亮度 < 200 视为息屏/AOD（防止把息屏显示拉满烧屏）
                    if [ "$CURRENT" -ge 200 ] 2>/dev/null && [ "$CURRENT" -lt "$TARGET" ] 2>/dev/null; then
                        echo "$TARGET" > "$BRIGHTNESS" 2>/dev/null
                        log "亮度被压低 $CURRENT → 拉回 $TARGET"
                    fi
                fi
            fi
        fi

        # 安全睡眠：sleep 失败也强制等待，防止空转刷 CPU
        sleep "$INTERVAL" 2>/dev/null || sleep 2
    done
}

main
