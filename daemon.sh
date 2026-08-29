#!/system/bin/sh
# ============================================================
# 亮度锁定器 - 守护进程
# 作用：常驻后台，防止系统（温控/自动亮度）把屏幕亮度压低
#
# 工作原理：
#   1. 每 2 秒检查一次锁定开关（模块目录 config 文件）
#   2. 开关开启时，检查屏幕是否亮着（bl_power=0 表示亮）
#   3. 如果亮度被系统压低到目标值以下，立即拉回目标值
#
# 配置项（通过 KSU WebUI 或直接编辑 config 文件）：
#   enabled=1          # 1=锁定开启, 0=关闭
#   target=4095        # 目标亮度值（小米14Pro最大4095）
#   interval=2         # 检查间隔（秒）
# ============================================================

MODDIR=${0%/*}
CONFIG="$MODDIR/config"

# ---------- 读取配置（带默认值） ----------
read_config() {
    # 配置不存在时创建默认配置
    if [ ! -f "$CONFIG" ]; then
        echo "enabled=1" > "$CONFIG"
        echo "target=4095" >> "$CONFIG"
        echo "interval=2" >> "$CONFIG"
        chmod 644 "$CONFIG"
    fi

    # 解析配置
    ENABLED=$(grep -E "^enabled=" "$CONFIG" 2>/dev/null | cut -d= -f2 | tr -d ' ')
    TARGET=$(grep -E "^target=" "$CONFIG" 2>/dev/null | cut -d= -f2 | tr -d ' ')
    INTERVAL=$(grep -E "^interval=" "$CONFIG" 2>/dev/null | cut -d= -f2 | tr -d ' ')

    # 默认值兜底
    [ -z "$ENABLED" ] && ENABLED=1
    [ -z "$TARGET" ] && TARGET=4095
    [ -z "$INTERVAL" ] || [ "$INTERVAL" -lt 1 ] 2>/dev/null && INTERVAL=2
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
    find_brightness
    if [ -z "$BRIGHTNESS" ]; then
        echo "[$(date)] 错误：未找到亮度节点！守护退出" >> "$MODDIR/daemon.log"
        exit 1
    fi

    echo "[$(date)] 亮度守护启动，节点=$BRIGHTNESS" >> "$MODDIR/daemon.log"

    while true; do
        read_config

        # 锁定开启且屏幕亮着时，检查并拉回亮度
        if [ "$ENABLED" = "1" ]; then
            if is_screen_on; then
                CURRENT=$(cat "$BRIGHTNESS" 2>/dev/null)
                # 数值比较：当前亮度低于目标时拉回
                if [ -n "$CURRENT" ] && [ "$CURRENT" -lt "$TARGET" ] 2>/dev/null; then
                    echo "$TARGET" > "$BRIGHTNESS" 2>/dev/null
                    echo "[$(date)] 亮度被压低 $CURRENT → 拉回 $TARGET" >> "$MODDIR/daemon.log"
                fi
            fi
        fi

        sleep "$INTERVAL"
    done
}

main
