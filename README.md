<p align="center">
  <img src="https://img.shields.io/badge/亮度锁定器-1.0-3482FF?style=for-the-badge&logo=android&logoColor=white" alt="版本"/>
  <img src="https://img.shields.io/badge/License-MIT-34C759?style=for-the-badge" alt="License"/>
  <img src="https://img.shields.io/badge/Platform-KSU%20%7C%20APatch%20%7C%20Magisk%20%7C%20Kitsune-F7931E?style=for-the-badge" alt="平台"/>
</p>

<p align="center">
  <b>🌞 解决安卓温控降亮度问题 —— 屏幕亮度被系统悄悄压低？一键锁定！</b>
</p>

<p align="center">
  <a href="README.md">中文</a> · <a href="README_EN.md">English</a>
</p>

---

## 📖 简介

在户外阳光下使用手机时，系统（温控/自动亮度策略）常常会把屏幕亮度**悄悄压低**，导致明明已经拉到最大却还是看不清屏幕。

**亮度锁定器**是一个常驻后台的守护模块，它会持续检测屏幕亮度，一旦发现被系统压低到目标值以下，**立即拉回**，让屏幕始终保持你设定的亮度。

> ⚠️ **本模块由 AI 辅助生成**，代码经过多重安全审查与逻辑测试，但使用前请知悉风险（详见 [免责声明](#-免责声明)）。

---

## ✨ 特性

- 🛡️ **温控对抗**：持续检测，亮度被压低立即拉回（默认 1 秒检测一次）
- 🔒 **默认关闭**：安装后不干预系统，需要时在 WebUI 一键开启
- 🎯 **目标跟随**：首次开启时自动锁定系统当前亮度，也可手动调整（1000~4095）
- 📊 **实时状态**：WebUI 显示当前亮度 / 目标亮度 / 守护进程状态 / 日志
- 🧹 **卸载干净**：删除模块即完全移除，守护进程自动退出，无残留
- 🔌 **多平台兼容**：KernelSU / APatch / Magisk / 狐狸面具（Kitsune Mask）

---

## 🔧 兼容性

| 面具 | 守护功能 | WebUI | 说明 |
|------|:--------:|:-----:|------|
| **KernelSU (KSU)** | ✅ | ✅ | 完整支持 |
| **APatch** | ✅ | ✅ | 复用 KSU WebUI API |
| **狐狸面具 (Kitsune Mask)** | ✅ | ❌ | 终端命令控制 |
| **Magisk 官方** | ✅ | ❌ | 官方不支持 webroot |

> 📌 Magisk / 狐狸面具无 WebUI 是面具本身不支持（topjohnwu 明确不做），非本模块限制。

---

## 📦 安装

### 前置要求
- 已 root（KSU / APatch / Magisk / 狐狸面具之一）
- 设备已解锁 bootloader

### 步骤
1. 下载 `亮度锁定器_1.0.zip`
2. 打开面具管理器 → **模块** → **从本地安装** → 选择 zip
3. 安装器会**自动检测面具环境**：
   - ✅ 兼容 → 继续
   - ❌ 不兼容（无面具）→ 自动终止安装
4. 按键确认：
   - **[音量+] = 确认安装**
   - **[音量-] = 取消安装**
   - 15 秒无操作自动取消
5. 重启手机

---

## 🎛️ 使用方法

### KSU / APatch（WebUI）
1. 打开面具管理器 → 模块 → **亮度锁定器**
2. 点击 **UI / 网页图标** 打开控制界面
3. 打开 **锁定亮度** 开关即可

### Magisk / 狐狸面具（终端）
```bash
# 开启锁定
echo enabled=1 > /data/adb/modules/brightness_lock/config

# 关闭锁定
echo enabled=0 > /data/adb/modules/brightness_lock/config

# 查看状态
cat /data/adb/modules/brightness_lock/config
```

---

## ⚙️ 配置说明

配置文件位于 `/data/adb/modules/brightness_lock/config`：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `enabled` | `0` | 锁定开关（0=关闭，1=开启） |
| `target` | 系统当前亮度 | 目标亮度值（100~4095） |
| `interval` | `1` | 检测间隔（秒），越短对抗温控越激进 |

> 首次启动时 `target` 自动填充为系统当前亮度，之后可在 WebUI 或终端手动调整。

---

## 🗑️ 卸载

1. 面具管理器 → 模块 → **亮度锁定器** → **卸载**
2. 守护进程会检测到模块被删除，**自动退出**，不留任何残留

> 模块不修改系统分区，卸载后即完全干净。

---

## ⚠️ 临时 Root 说明

- 本模块**不修改系统分区**（只写 `/data/adb` 与 `/sys` 节点）
- **临时 Root（重启失效）可以安装**，但重启后无 Root 环境不会自动生效
- 需要重新获取 Root 后手动启动守护，或改用持久 Root（KSU / Magisk / APatch）

---

## ❓ 常见问题

**Q: 开启后屏幕一直 4095，会不会烧屏？**
A: OLED 长时间最高亮度确实有老化风险，建议户外使用、室内关闭（WebUI 一键切换）。

**Q: 为什么 Magisk 上没有 WebUI？**
A: Magisk 官方不支持模块 WebUI 功能，这是面具的限制，请用终端命令控制。

**Q: 模块删了亮度还会被改吗？**
A: 不会。守护进程检测到模块被删除会立即自杀退出。

**Q: 支持其他机型吗？**
A: 守护逻辑通用（自动探测 `/sys/class/backlight/*/brightness`），小米 14 Pro 实测通过。

---

## 📜 免责声明

- 本模块为 **AI 辅助生成**，虽经代码审查与逻辑测试，但仍可能存在未知问题
- 使用本模块导致的一切后果（包括但不限于屏幕老化、系统异常）**由使用者自行承担**
- 请自行决定是否使用，**使用即视为同意以上条款**

---

## 📄 License

[MIT](LICENSE) © 酷安@星陨Lite

---

<p align="center">
  <sub>Made with ❤️ and 🤖 · 酷安@星陨Lite</sub>
</p>
