#!/system/bin/sh
# ============================================================
# 亮度锁定器 - 多机型诊断脚本 v1.0（备用）
# 用途：在不同机型的手机上一键收集亮度相关信息，
#       用于验证模块兼容性（用户手头：小米10Ultra/11Pro/K80/14Pro）
# 用法：sh /storage/emulated/0/Download/device_diag.sh
#       或 root 终端直接执行，输出自动保存到 Download/ 目录
# ============================================================

OUT=/storage/emulated/0/Download/backlight_diag.txt
MODDIR=/data/adb/modules/brightness_lock

echo "===== 亮度锁定器 多机型诊断 $(date '+%Y-%m-%d %H:%M:%S') =====" | tee "$OUT"
echo "设备: $(getprop ro.product.model) ($(getprop ro.product.device))" | tee -a "$OUT"
echo "Android: $(getprop ro.build.version.release) | SDK: $(getprop ro.build.version.sdk)" | tee -a "$OUT"
echo "内核: $(uname -r)" | tee -a "$OUT"
echo "" | tee -a "$OUT"

echo "===== 1. 背光节点探测 =====" | tee -a "$OUT"
# 遍历所有 backlight 设备，找有效亮度节点
for dev in /sys/class/backlight/*/; do
    [ -f "$dev/brightness" ] || continue
    echo "节点: $dev" | tee -a "$OUT"
    echo "  当前亮度: $(cat "$dev/brightness" 2>/dev/null)" | tee -a "$OUT"
    echo "  最大亮度: $(cat "$dev/max_brightness" 2>/dev/null)" | tee -a "$OUT"
    echo "  bl_power: $(cat "$dev/bl_power" 2>/dev/null)" | tee -a "$OUT"
    echo "  类型: $(cat "$dev/type" 2>/dev/null)" | tee -a "$OUT"
    # 符号链接指向（判断真实设备）
    echo "  链接目标: $(readlink -f "$dev" 2>/dev/null)" | tee -a "$OUT"
    echo "" | tee -a "$OUT"
done

echo "===== 2. 模块状态 =====" | tee -a "$OUT"
if [ -d "$MODDIR" ]; then
    echo "模块已安装: v$(grep version= "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)" | tee -a "$OUT"
    echo "配置文件:" | tee -a "$OUT"
    cat "$MODDIR/config" 2>/dev/null | tee -a "$OUT"
    echo "" | tee -a "$OUT"
    echo "守护探测节点: $(cat "$MODDIR/brightness_path" 2>/dev/null || echo '未生成（守护未运行？）')" | tee -a "$OUT"
    echo "机型最大亮度: $(cat "$MODDIR/brightness_max" 2>/dev/null || echo '未生成')" | tee -a "$OUT"
    echo "" | tee -a "$OUT"
    echo "守护进程: $(pgrep -f 'brightness_lock/daemon.sh' | head -1 | xargs -r echo 'PID=')" | tee -a "$OUT"
    echo "守护日志（末10行）:" | tee -a "$OUT"
    tail -10 "$MODDIR/daemon.log" 2>/dev/null | tee -a "$OUT"
else
    echo "❌ 模块未安装" | tee -a "$OUT"
fi

echo "" | tee -a "$OUT"
echo "===== 3. 额外信息（温控/自动亮度相关） =====" | tee -a "$OUT"
# 常见额外亮度节点（部分机型有）
for extra in /sys/class/leds/lcd-backlight/brightness \
             /sys/devices/virtual/mi_display/disp_feature/disp-DSI-0/doze_brightness \
             /sys/class/backlight/panel0-backlight/brightness_clone; do
    if [ -f "$extra" ]; then
        echo "$extra = $(cat "$extra" 2>/dev/null)" | tee -a "$OUT"
    fi
done
# 温控相关（如有权限）
for thermal in /sys/class/thermal/thermal_zone*/temp; do
    [ -r "$thermal" ] || continue
    Z=$(basename "$(dirname "$thermal")")
    T=$(cat "$thermal" 2>/dev/null)
    echo "  温区 $Z: $T" | tee -a "$OUT"
done | head -20

echo "" | tee -a "$OUT"
echo "===== 诊断完成 =====" | tee -a "$OUT"
echo "结果已保存: $OUT" | tee -a "$OUT"
