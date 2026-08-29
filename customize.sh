#!/system/bin/sh
# ============================================================
# 亮度锁定器 - 安装脚本 1.0（正式版）
# 功能：
#   1. 检测当前面具环境（Magisk / KSU / 狐狸面具 / APatch）
#   2. 显示支持的面具列表
#   3. 不兼容的环境直接退出安装
#   4. 安装确认：音量上=确认，音量下=取消
#   5. 临时 Root 说明
#
# 兼容矩阵：
#   ✅ KSU        （KernelSU）      - 完整支持（含 WebUI）
#   ✅ 狐狸面具    （Kitsune Mask）  - 守护功能支持（无 WebUI）
#   ✅ APatch     - 完整支持（含 WebUI，复用 KSU API）
#   ✅ Magisk 官方 - 守护功能支持（无 WebUI，官方不支持 webroot）
# ============================================================

# ---------- ui_print 兼容封装 ----------
ui_print() {
    echo "$1"
}

# ---------- 检测面具环境 ----------
# 输出：magisk / kitsune / ksu / apatch / unknown
detect_manager() {
    # 1) KSU：有 ksud 二进制（KernelSU 的标志）
    if [ -x /data/adb/ksud ] || [ -x /data/adb/ksu ] || [ -f /data/adb/ksu ]; then
        echo "ksu"
        return 0
    fi

    # 2) APatch：有 apd 守护进程/二进制（KernelPatch 的标志）
    if [ -x /data/adb/apd ] || [ -f /data/adb/apd ] || [ -x /data/adb/kpatch ]; then
        echo "apatch"
        return 0
    fi

    # 3) Magisk 系列：有 magisk 二进制
    if [ -x /data/adb/magisk/magisk ] || command -v magisk >/dev/null 2>&1 || [ -f /data/adb/magisk ]; then
        # 区分官方 Magisk 和狐狸面具（Kitsune Mask）
        # 狐狸面具的 magisk 二进制带 Kitsune 特征（strings 含 "Kitsune" 或版本含 delta/kitsune）
        if [ -x /data/adb/magisk/magisk ]; then
            # 检查二进制里是否含 Kitsune 特征（狐狸面具）
            if strings /data/adb/magisk/magisk 2>/dev/null | grep -qi "kitsune"; then
                echo "kitsune"
                return 0
            fi
        fi
        # 也检查版本信息
        VER=$(magisk -v 2>/dev/null || /data/adb/magisk/magisk -v 2>/dev/null)
        case "$VER" in
            *[Dd]elta*|*[Kk]itsune*) echo "kitsune" ;;
            *) echo "magisk" ;;
        esac
        return 0
    fi

    echo "unknown"
    return 1
}

# ---------- 按键监听：音量上=确认(0)，音量下=取消(1)，超时=取消(1) ----------
wait_for_key() {
    # 用真实时间戳计时（不能用循环次数！安装界面事件流活跃，
    # getevent 几乎瞬间返回无关事件，循环会飞快跑完，
    # 导致 15 秒实际只有四五秒）
    local START=$(date +%s)
    local NOW=$START
    while [ $((NOW - START)) -lt 15 ]; do
        # 读取一个输入事件，匹配音量键（KEY_VOLUMEUP=115=0x73, KEY_VOLUMEDOWN=114=0x72）
        EVENT=$(timeout 1 getevent -c 1 2>/dev/null | grep -E "VOLUME(UP|DOWN)|0073|0072" | head -1)
        case "$EVENT" in
            *VOLUMEUP*|*"0073"*) return 0 ;;   # 音量上 → 确认
            *VOLUMEDOWN*|*"0072"*) return 1 ;; # 音量下 → 取消
        esac
        NOW=$(date +%s)
    done
    return 1  # 超时默认取消（安全优先）
}

# ============================================================
# 主流程
# ============================================================

# ---------- 检测环境 ----------
MANAGER=$(detect_manager)

ui_print "======================================"
ui_print "  亮度锁定器 1.0（正式版）"
ui_print "======================================"
ui_print ""
ui_print "  兼容面具："
ui_print "    ✅ KernelSU (KSU)     - 完整支持"
ui_print "    ✅ APatch             - 完整支持"
ui_print "    ✅ 狐狸面具 Kitsune   - 守护功能"
ui_print "    ✅ Magisk 官方        - 守护功能"
ui_print "    （KSU/APatch 带 WebUI 界面，"
ui_print "      Magisk/狐狸无 WebUI，用终端命令控制）"
ui_print ""
ui_print "  ⚠️  临时 Root 说明："
ui_print "  - 本模块不修改系统分区（只写 /data/adb）"
ui_print "  - 临时 Root（重启失效）可以安装，"
ui_print "    但重启后无 Root 环境不会自动生效"
ui_print "  - 需重新获取 Root 后手动启动守护，"
ui_print "    或改用持久 Root（KSU/Magisk/APatch）"
ui_print "  - 卸载干净：删除模块即完全移除，"
ui_print "    守护进程自动退出，无残留"
ui_print ""
ui_print "  📱 机型测试声明："
ui_print "  - 本模块仅在 小米 14 Pro 上测试通过"
ui_print "  - 其他机型不保证可以生效，请自行测试"
ui_print ""

case "$MANAGER" in
    ksu)
        ui_print "  🎯 检测到：KernelSU (KSU)"
        ui_print "  ✅ 兼容，可完整安装（含 WebUI）"
        ;;
    apatch)
        ui_print "  🎯 检测到：APatch"
        ui_print "  ✅ 兼容，可完整安装（含 WebUI）"
        ;;
    kitsune)
        ui_print "  🎯 检测到：狐狸面具 (Kitsune Mask)"
        ui_print "  ✅ 兼容（守护功能可用，无 WebUI）"
        ;;
    magisk)
        ui_print "  🎯 检测到：Magisk 官方版"
        ui_print "  ✅ 兼容（守护功能可用，无 WebUI）"
        ;;
    *)
        ui_print "  ❌ 未检测到已知面具环境！"
        ui_print "  （需要 Magisk / KSU / 狐狸面具 / APatch 之一）"
        ui_print "  终止安装。"
        exit 1
        ;;
esac

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
    exit 1
fi

# ---------- 设置模块内脚本权限 ----------
chmod 755 "$MODPATH/service.sh" 2>/dev/null
chmod 755 "$MODPATH/daemon.sh" 2>/dev/null
chmod 644 "$MODPATH/config" 2>/dev/null

ui_print "  ✅ 安装完成"
ui_print "  重启后生效"
ui_print "  KSU/APatch：管理器里打开 WebUI"
ui_print "  Magisk/狐狸：终端执行以下命令控制："
ui_print "    # 开启锁定"
ui_print "    echo enabled=1 > /data/adb/modules/brightness_lock/config"
ui_print "    # 关闭锁定"
ui_print "    echo enabled=0 > /data/adb/modules/brightness_lock/config"
ui_print "    # 查看状态"
ui_print "    cat /data/adb/modules/brightness_lock/config"
