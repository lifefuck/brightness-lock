#!/system/bin/sh
# ============================================================
# 亮度锁定器 - 安装脚本 v1.3
# 功能：
#   1. 安装前确认：音量上=确认安装，音量下=取消安装
#   2. 设置脚本权限
#
# 说明：AI 生成的模块可能有未知 bug，安装前必须确认
# ============================================================

# ---------- ui_print 兼容封装 ----------
ui_print() {
    echo "$1"
}

# ---------- 按键监听：音量上=确认(0)，音量下=取消(1)，超时=取消(1) ----------
wait_for_key() {
    local i=0
    # 最多监听 15 秒
    while [ "$i" -lt 15 ]; do
        # 读取一个输入事件，匹配音量键（KEY_VOLUMEUP=115=0x73, KEY_VOLUMEDOWN=114=0x72）
        EVENT=$(timeout 1 getevent -c 1 2>/dev/null | grep -E "VOLUME(UP|DOWN)|0073|0072" | head -1)
        case "$EVENT" in
            *VOLUMEUP*|*"0073"*) return 0 ;;   # 音量上 → 确认
            *VOLUMEDOWN*|*"0072"*) return 1 ;; # 音量下 → 取消
        esac
        i=$((i + 1))
    done
    return 1  # 超时默认取消（安全优先）
}

# ============================================================
# 主流程
# ============================================================

ui_print "======================================"
ui_print "  亮度锁定器 v1.3"
ui_print "======================================"
ui_print ""
ui_print "  ⚠️  此模块为 AI 模块，可能会有奇怪的 bug"
ui_print ""
ui_print "  确认安装吗？"
ui_print ""
ui_print "  [音量+] = 确认安装"
ui_print "  [音量-] = 取消安装"
ui_print "  (15 秒无操作自动取消)"
ui_print ""
ui_print "  请按键..."

# 等待用户按键
if wait_for_key; then
    ui_print ""
    ui_print "  ✅ 已确认，开始安装..."
    ui_print ""
else
    ui_print ""
    ui_print "  ❌ 已取消安装（音量- 或超时）"
    # 返回非零退出码，通知安装器中止
    exit 1
fi

# ---------- 设置模块内脚本权限 ----------
chmod 755 "$MODPATH/service.sh" 2>/dev/null
chmod 755 "$MODPATH/daemon.sh" 2>/dev/null
chmod 644 "$MODPATH/config" 2>/dev/null

ui_print "  ✅ 安装完成"
ui_print "  重启后生效，KSU 管理器可打开 WebUI"
