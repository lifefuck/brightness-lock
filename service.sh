#!/system/bin/sh
# ============================================================
# 亮度锁定器 - 开机启动脚本 v1.2
# 作用：系统启动后启动亮度守护进程（后台循环）
#
# v1.2 修复：
#   - 启动前检测模块是否被标记删除（KSU 卸载残留时不自启）
# ============================================================

MODDIR=${0%/*}

# 延迟启动，等待系统完全初始化（避免太早抢系统亮度）
sleep 15

# 模块已被标记删除（KSU/Magisk 卸载）→ 不自启
if [ ! -f "$MODDIR/module.prop" ] || [ -f "$MODDIR/remove" ] || [ -f "$MODDIR/.remove" ]; then
    exit 0
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
