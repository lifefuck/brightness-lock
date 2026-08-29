<p align="center">
  <img src="https://img.shields.io/badge/Brightness%20Lock-1.0-3482FF?style=for-the-badge&logo=android&logoColor=white" alt="Version"/>
  <img src="https://img.shields.io/badge/License-MIT-34C759?style=for-the-badge" alt="License"/>
  <img src="https://img.shields.io/badge/Platform-KSU%20%7C%20APatch%20%7C%20Magisk%20%7C%20Kitsune-F7931E?style=for-the-badge" alt="Platform"/>
</p>

<p align="center">
  <b>🌞 Fix Android thermal brightness throttling — screen dimmed by the system? Lock it back!</b>
</p>

<p align="center">
  <a href="README.md">中文</a> · <a href="README_EN.md">English</a>
</p>

---

## 📖 Introduction

Under bright sunlight, Android's thermal management / auto-brightness often **silently dims your screen** — even at max brightness it's still hard to see.

**Brightness Lock** is a background daemon module that continuously monitors screen brightness. Whenever the system pushes it below your target value, it **immediately restores it**, keeping your screen at the brightness you set.

> ⚠️ **This module is AI-assisted.** The code has been security-reviewed and logic-tested, but please acknowledge the risks (see [Disclaimer](#-disclaimer)).

---

## ✨ Features

- 🛡️ **Anti-throttling**: continuously detects and restores dimmed brightness (1s interval by default)
- 🔒 **Off by default**: no interference until you enable it in WebUI
- 🎯 **Smart target**: auto-locks to current brightness on first enable, adjustable (1000~4095)
- 📊 **Live status**: WebUI shows current/target brightness, daemon status, and logs
- 🧹 **Clean uninstall**: removing the module fully removes it; daemon self-terminates
- 🔌 **Multi-platform**: KernelSU / APatch / Magisk / Kitsune Mask

---

## 🔧 Compatibility

| Manager | Daemon | WebUI | Notes |
|---------|:------:|:-----:|-------|
| **KernelSU (KSU)** | ✅ | ✅ | Full support |
| **APatch** | ✅ | ✅ | Reuses KSU WebUI API |
| **Kitsune Mask** | ✅ | ❌ | Terminal control |
| **Magisk (official)** | ✅ | ❌ | No webroot support officially |

> 📌 Magisk/Kitsune lack WebUI because the manager itself doesn't support it (topjohnwu explicitly refuses), not a module limitation.

---

## 📱 Device Test Status

> ⚠️ This module is **only tested on Xiaomi 14 Pro**. It is **NOT guaranteed to work on other devices** — test at your own discretion.

The daemon auto-detects the brightness node (`/sys/class/backlight/*/brightness`) and is quite generic, but **kernel/SELinux differences between vendors may break compatibility**. Feel free to open an [Issue](https://github.com/lifefuck/brightness-lock/issues).

---

## 📦 Installation

### Requirements
- Rooted device (KSU / APatch / Magisk / Kitsune)
- Unlocked bootloader

### Steps
1. Download `brightness_lock_1.0.zip`
2. Open manager → **Modules** → **Install from storage** → select zip
3. Installer **auto-detects your manager**:
   - ✅ Compatible → proceed
   - ❌ Unknown environment → aborts automatically
4. Key confirmation:
   - **[Volume+] = install**
   - **[Volume-] = cancel**
   - Auto-cancels after 15s of no input
5. Reboot

---

## 🎛️ Usage

### KSU / APatch (WebUI)
1. Manager → Modules → **Brightness Lock**
2. Tap the **UI / web icon** to open the control panel
3. Toggle **Lock Brightness** on

### Magisk / Kitsune (Terminal)
```bash
# Enable lock
echo enabled=1 > /data/adb/modules/brightness_lock/config

# Disable lock
echo enabled=0 > /data/adb/modules/brightness_lock/config

# Check status
cat /data/adb/modules/brightness_lock/config
```

---

## ⚙️ Configuration

Config file: `/data/adb/modules/brightness_lock/config`

| Key | Default | Description |
|-----|---------|-------------|
| `enabled` | `0` | Lock switch (0=off, 1=on) |
| `target` | current brightness | Target brightness (100~4095) |
| `interval` | `1` | Check interval (s), lower = more aggressive |

> On first run, `target` auto-fills with current system brightness. Adjust later via WebUI or terminal.

---

## 🗑️ Uninstall

1. Manager → Modules → **Brightness Lock** → **Uninstall**
2. The daemon detects removal and **self-terminates** — zero residue.

> The module never touches system partitions; uninstall is fully clean.

---

## ⚠️ Temporary Root

- This module **does not modify system partitions** (only `/data/adb` and `/sys` nodes)
- **Temporary root (lost on reboot) can install**, but the daemon won't auto-start after reboot
- Re-obtain root and start the daemon manually, or use persistent root (KSU / Magisk / APatch)

---

## ❓ FAQ

**Q: Screen stuck at 4095 — burn-in risk?**
A: OLED at max brightness long-term does carry aging risk. Use outdoors and turn it off indoors (one tap in WebUI).

**Q: Why no WebUI on Magisk?**
A: Magisk officially doesn't support module WebUI. Use terminal commands instead.

**Q: Will brightness still be modified after uninstall?**
A: No. The daemon self-terminates as soon as it detects module removal.

**Q: Other devices supported?**
A: The daemon auto-detects `/sys/class/backlight/*/brightness`, so it's generic. Tested on Xiaomi 14 Pro.

---

## 📜 Disclaimer

- This module is **AI-assisted**; code reviewed and logic-tested, but unknown issues may remain
- All consequences of use (including screen aging, system issues) **are the user's responsibility**
- Use at your own discretion — **use implies agreement**

---

## 📄 License

[MIT](LICENSE) © XingYunLite (酷安@星陨Lite)

---

<p align="center">
  <sub>Made with ❤️ and 🤖 · 酷安@星陨Lite</sub>
</p>
