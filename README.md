# MDViewer

A lightweight macOS menubar app that monitors your clipboard and instantly renders any Markdown content in a floating, always-on-top panel.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Features

- **Clipboard monitoring** — detects Markdown as you copy and renders it automatically
- **Floating panel** — stays above other windows; draggable anywhere on screen
- **RTL/LTR detection** — automatically sets text direction based on content (Hebrew, Arabic, Latin)
- **Light & Dark mode** — adapts to the system appearance
- **Global hotkey** — toggle the panel with `Cmd+Shift+M` from anywhere
- **Bilingual UI** — switch between English and Hebrew in Settings
- **Zero dependencies** — pure Swift, no third-party packages

## Requirements

- macOS 13 Ventura or later
- Xcode 15+
- Accessibility permission (for the global hotkey)

## Installation

### Option A — Download (recommended)

1. Go to the [Releases page](https://github.com/DanielGabbay/MDViewer/releases) and download the latest `MDViewer.zip`.
2. Extract the zip — you'll find `MDViewer.app` and `install.sh`.
3. Run the installer:
   ```bash
   bash install.sh
   ```
   This copies the app to `/Applications` and removes the macOS quarantine flag so it launches without security warnings.
4. Open `/Applications/MDViewer.app`.

> **Alternatively**, drag `MDViewer.app` to `/Applications` manually, then on first launch right-click > **Open** and confirm.

### Option B — Build from source

1. Clone the repository:
   ```
   git clone https://github.com/DanielGabbay/MDViewer.git
   ```
2. Open `MDViewer.xcodeproj` in Xcode.
3. Select your development team in *Signing & Capabilities*.
4. Build and run (`Cmd+R`).

To use as a persistent menubar app, archive the build (*Product → Archive*) and copy the resulting `.app` to `/Applications`.

## Usage

- **Copy any text** — if it contains Markdown, it renders immediately in the panel.
- **`Cmd+Shift+M`** — show or hide the panel at any time.
- **📌 / 📍 button** — toggle always-on-top mode.
- **⚙️ button** — open Settings to configure clipboard monitoring, opacity, and language.

## Project Structure

```
MDViewer/
├── AppDelegate.swift            # App lifecycle, menubar icon, menu setup
├── main.swift                   # Entry point
├── ClipboardMonitor.swift       # Polls NSPasteboard for changes
├── FloatingWindowController.swift  # NSPanel-based floating window
├── MarkdownRenderer.swift       # Markdown → HTML converter + CSS theming
├── HotkeyManager.swift          # Global/local keyboard event monitoring
├── LocalizationManager.swift    # All UI strings (English + Hebrew)
├── PreferencesManager.swift     # UserDefaults persistence
└── SettingsWindowController.swift  # Settings UI
```

## How It Works

1. `ClipboardMonitor` polls `NSPasteboard` every 500ms.
2. On change, `ClipboardMonitor.isLikelyMarkdown(_:)` checks for common Markdown patterns.
3. `MarkdownRenderer.render(_:)` converts the content to styled HTML, detecting RTL/LTR direction.
4. The HTML is displayed in a `WKWebView` inside the floating `NSPanel`.

## License

MIT — see [LICENSE](LICENSE) for details.
