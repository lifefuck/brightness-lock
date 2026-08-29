#!/system/bin/sh
# ============================================================
# 亮度锁定器 - 开机启动脚本 v1.3
# 作用：系统启动后启动亮度守护进程（后台循环）
#
# v1.3 修复：
#   - 重启后强制重置为关闭状态（防止开机闪光弹：
#     黑暗中开机，守护立刻把亮度拉到最大会刺眼）
#   - 启动前检测模块是否被标记删除（KSU 卸载残留时不自启）
# ============================================================

MODDIR=${0%/*}

# 延迟启动，等待系统完全初始化（避免太早抢系统亮度）
sleep 15

# 模块已被标记删除（KSU/Magisk 卸载）→ 不自启
if [ ! -f "$MODDIR/module.prop" ] || [ -f "$MODDIR/remove" ] || [ -f "$MODDIR/.remove" ]; then
    exit 0
fi

# 重启后重置为关闭状态（防止开机闪光弹）
# 用户需要在 WebUI / 终端手动开启锁定
# 用 grep -v + mv 实现（兼容 toybox，不依赖 sed -i）
if [ -f "$MODDIR/config" ]; then
    grep -v '^enabled=' "$MODDIR/config" > "$MODDIR/config.tmp" 2>/dev/null
    echo "enabled=0" >> "$MODDIR/config.tmp" 2>/dev/null
    mv "$MODDIR/config.tmp" "$MODDIR/config" 2>/dev/null
    chmod 644 "$MODDIR/config" 2>/dev/null
fi

# 清理可能残留的旧守护进程（防重复实例）
if [ -f "$MODDIR/.daemon.pid" ]; then
    OLD_PID=$(cat "$MODDIR/.daemon.pid" 2>/dev/null | tr -d ' ')
    if [ -n "$OLD_PID" ]; then
        kill "$OLD_PID" 2>/dev/null
    fi
    rm -f "$MODDIR/.daemon.pid"
fi

# 启动守护进程
# setsid: 完全脱离控制终端和会话，防止被杀
# nohup: 忽略挂断信号
setsid sh "$MODDIR/daemon.sh" > "$MODDIR/daemon.out" 2>&1 &
