<p align="center">
  <img src="https://img.shields.io/badge/Xiaomi%2014%20Pro%20Brightness%20Boost-1.2-3482FF?style=for-the-badge&logo=android&logoColor=white" alt="Version"/>
  <img src="https://img.shields.io/badge/License-MIT-34C759?style=for-the-badge" alt="License"/>
  <img src="https://img.shields.io/badge/Platform-KSU%20%7C%20APatch%20%7C%20Magisk%20%7C%20Kitsune-F7931E?style=for-the-badge" alt="Platform"/>
</p>

<p align="center">
  <a href="https://github.com/lifefuck/brightness-lock/releases/latest">
    <img src="https://img.shields.io/github/v/release/lifefuck/brightness-lock?style=for-the-badge&label=Latest&color=3482FF" alt="Latest Release"/>
    <img src="https://img.shields.io/github/downloads/lifefuck/brightness-lock/total?style=for-the-badge&label=Downloads&color=34C759" alt="Downloads"/>
  </a>
</p>

<p align="center">
  <b>🌞 Fix Android thermal brightness throttling — screen dimmed by the system? Lock it instantly!</b>
</p>

<p align="center">
  <a href="README.md">中文</a> · <a href="README_EN.md">English</a>
</p>

---

## 📖 Introduction

Under bright sunlight, Android's thermal management / auto-brightness often **silently dims your screen** — even at max brightness it's still hard to see.

**Xiaomi 14 Pro Brightness Boost** is an event-driven background daemon module that continuously guards screen brightness. Whenever the system pushes it below your target value, it **instantly restores it with zero latency**, completely replacing outdated poll intervals.

> ⚠️ **This module is AI-assisted.** The code has been security-reviewed and logic-tested, but please acknowledge the risks (see [Disclaimer](#-disclaimer)).

---

## ✨ Features

- 🛡️ **Anti-throttling**: event-driven instant restoration when screen brightness is throttled
- 💤 **Deep Sleep**: completely suspends on screen off, 0 CPU wakeups and 0 idle drain
- 🎨 **Material You MD3**: elegant Monet dynamic theming with native Android 12+ aesthetics
- 🔒 **Off by default**: no interference until you enable it in WebUI
- 🎯 **Smart target**: auto-locks to current brightness on first enable, adjustable (100~4095)
- 📊 **Live status**: WebUI shows current/target brightness, daemon status, and live logs
- 🧹 **Clean uninstall**: removing the module fully removes it; daemon self-terminates
- 🔌 **Multi-platform**: KernelSU / APatch / Magisk / Kitsune Mask

---

## 🔧 Compatibility

| Manager | Daemon | WebUI | Notes |
|---------|:------:|:-----:|-------|
| **KernelSU (KSU)** | ✅ | ✅ | Full support with MD3 Monet WebUI |
| **APatch** | ✅ | ✅ | Reuses KSU WebUI API |
| **Kitsune Mask** | ✅ | ❌ | Terminal control |
| **Magisk (official)** | ✅ | ❌ | No webroot support officially |

---

## 📱 Device Notes

> ⚠️ This module is **tailored for Xiaomi 14 Pro (HyperOS)**. Other devices support automatic backlight node detection, but please test at your own discretion.

---

## 📦 Installation

### Requirements
- Rooted device (KSU / APatch / Magisk / Kitsune)
- Unlocked bootloader

### Steps
1. **Download**: Check the [Releases page](https://github.com/lifefuck/brightness-lock/releases) for the latest v1.2 zip
2. Open manager → **Modules** → **Install from storage** → select zip
3. Key confirmation:
   - **[Volume+] = install**
   - **[Volume-] = cancel**
4. Reboot

---

## 🎛️ Usage

### KSU / APatch (WebUI)
1. Manager → Modules → **Xiaomi 14 Pro Brightness Boost**
2. Tap the **UI / web icon** to open the Material You control panel
3. Toggle **Keep Brightness Locked** on

---

## 📄 License

[MIT](LICENSE) © life
