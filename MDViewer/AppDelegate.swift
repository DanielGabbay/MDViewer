import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var floatingWindowController: FloatingWindowController?
    var settingsWindowController: SettingsWindowController?
    let clipboardMonitor = ClipboardMonitor()
    let hotkeyManager = HotkeyManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menubar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            if let icon = NSImage(named: "MenubarIcon") {
                icon.isTemplate = true
                icon.size = NSSize(width: 18, height: 18)
                button.image = icon
            } else {
                button.image = NSImage(systemSymbolName: "doc.richtext", accessibilityDescription: "MD Viewer")
            }
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        setupMenu()

        // Floating window
        floatingWindowController = FloatingWindowController()
        floatingWindowController?.window?.orderFrontRegardless()
        floatingWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Clipboard monitor
        clipboardMonitor.onMarkdownDetected = { [weak self] markdown in
            DispatchQueue.main.async {
                self?.floatingWindowController?.renderMarkdown(markdown)
            }
        }
        if PreferencesManager.shared.autoMonitorClipboard {
            clipboardMonitor.start()
        }

        // Global hotkey
        hotkeyManager.onToggle = { [weak self] in
            self?.toggleFloatingWindow()
        }
        hotkeyManager.register()
    }

    func setupMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: L(.menuShow), action: #selector(toggleFloatingWindow), keyEquivalent: "m")
        toggleItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let monitorItem = NSMenuItem(title: L(.clipboardMonitor), action: #selector(toggleClipboardMonitor), keyEquivalent: "")
        monitorItem.state = PreferencesManager.shared.autoMonitorClipboard ? .on : .off
        monitorItem.target = self
        menu.addItem(monitorItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: L(.menuSettings), action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: L(.menuQuit), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu

        // Rebuild menu when language changes
        NotificationCenter.default.removeObserver(self, name: .languageChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rebuildMenu), name: .languageChanged, object: nil)
    }

    @objc func rebuildMenu() {
        setupMenu()
    }

    @objc func statusBarButtonClicked() {
        // Menu handles clicks
    }

    @objc func toggleFloatingWindow() {
        guard let wc = floatingWindowController, let window = wc.window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc func toggleClipboardMonitor() {
        let prefs = PreferencesManager.shared
        prefs.autoMonitorClipboard.toggle()
        if prefs.autoMonitorClipboard {
            clipboardMonitor.start()
        } else {
            clipboardMonitor.stop()
        }
        setupMenu()
    }

    @objc func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        // Ensure Settings appears above the floating panel
        if let fw = floatingWindowController?.window, fw.level == .floating {
            settingsWindowController?.window?.level = .floating
        } else {
            settingsWindowController?.window?.level = .normal
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
