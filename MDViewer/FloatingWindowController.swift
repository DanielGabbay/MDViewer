import AppKit
import WebKit

class FloatingWindowController: NSWindowController, NSWindowDelegate, WKNavigationDelegate {

    private var webView: WKWebView!
    private var toolbar: NSView!
    private var currentMarkdown: String = ""

    convenience init() {
        let prefs = PreferencesManager.shared
        let savedFrame = prefs.windowFrame

        let window = FloatingPanel(
            contentRect: savedFrame,
            styleMask: [.titled, .resizable, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.title = "MD Viewer"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isFloatingPanel = true
        window.level = prefs.alwaysOnTop ? .floating : .normal
        window.minSize = NSSize(width: 280, height: 180)
        window.isOpaque = false
        window.backgroundColor = .clear

        self.init(window: window)
        window.delegate = self

        setupContent()
        renderEmpty()
        restorePosition()
    }

    private func setupContent() {
        guard let window = window else { return }

        // Root container
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor(named: "WindowBackground")?.cgColor
            ?? NSColor.windowBackgroundColor.cgColor
        container.layer?.cornerRadius = 12
        container.layer?.masksToBounds = true

        window.contentView = container

        // Toolbar
        toolbar = buildToolbar()
        container.addSubview(toolbar)

        // WebView config
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.wantsLayer = true
        webView.layer?.cornerRadius = 0
        webView.setValue(false, forKey: "drawsBackground")
        container.addSubview(webView)

        // Layout
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        webView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: container.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 36),

            webView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }

    private func buildToolbar() -> NSView {
        let bar = NSView()
        bar.wantsLayer = true
        bar.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.15).cgColor

        // Title label — centered
        let label = NSTextField(labelWithString: "MD Viewer")
        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabelColor
        label.alignment = .center
        bar.addSubview(label)

        // Always on top (pin) button — left side, after the traffic-light area (80px offset)
        let pinBtn = NSButton(title: PreferencesManager.shared.alwaysOnTop ? "📌" : "📍", target: self, action: #selector(toggleAlwaysOnTop))
        pinBtn.bezelStyle = .inline
        pinBtn.isBordered = false
        pinBtn.tag = 100
        bar.addSubview(pinBtn)

        // Settings button — right side
        let settingsBtn = NSButton(title: "⚙️", target: self, action: #selector(openSettings))
        settingsBtn.bezelStyle = .inline
        settingsBtn.isBordered = false
        bar.addSubview(settingsBtn)

        // Layout
        label.translatesAutoresizingMaskIntoConstraints = false
        pinBtn.translatesAutoresizingMaskIntoConstraints = false
        settingsBtn.translatesAutoresizingMaskIntoConstraints = false

        // Traffic-light buttons are always at 80px from their side.
        // On RTL system layouts they move to the right, so we swap sides accordingly.
        let isRTL = NSApp.userInterfaceLayoutDirection == .rightToLeft

        NSLayoutConstraint.activate([
            // Settings button — on the same side as the traffic lights (80px inset)
            isRTL
                ? settingsBtn.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -80)
                : settingsBtn.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 10),
            settingsBtn.centerYAnchor.constraint(equalTo: bar.centerYAnchor),

            // Pin button — next to settings
            isRTL
                ? pinBtn.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -80)
                : pinBtn.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 40),
            pinBtn.centerYAnchor.constraint(equalTo: bar.centerYAnchor),

            // Title — always centered
            label.centerXAnchor.constraint(equalTo: bar.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
        ])

        return bar
    }

    @objc private func toggleAlwaysOnTop() {
        let prefs = PreferencesManager.shared
        prefs.alwaysOnTop.toggle()
        window?.level = prefs.alwaysOnTop ? .floating : .normal
        // Update pin button title
        if let btn = toolbar.viewWithTag(100) as? NSButton {
            btn.title = prefs.alwaysOnTop ? "📌" : "📍"
        }
    }

    @objc private func openSettings() {
        (NSApp.delegate as? AppDelegate)?.openSettings()
    }

    func renderMarkdown(_ markdown: String) {
        currentMarkdown = markdown
        let html = MarkdownRenderer.render(markdown)
        webView.loadHTMLString(html, baseURL: nil)
    }

    func renderEmpty() {
        let html = MarkdownRenderer.renderEmpty()
        webView.loadHTMLString(html, baseURL: nil)
    }

    // MARK: - Window save/restore

    func windowDidMove(_ notification: Notification) {
        saveFrame()
    }

    func windowDidResize(_ notification: Notification) {
        saveFrame()
    }

    private func saveFrame() {
        guard let frame = window?.frame else { return }
        PreferencesManager.shared.windowFrame = frame
    }

    private func restorePosition() {
        guard let window = window else { return }
        let saved = PreferencesManager.shared.windowFrame
        // Validate the saved frame is on a visible screen
        let onScreen = NSScreen.screens.contains { screen in
            screen.visibleFrame.intersects(saved)
        }
        if onScreen {
            window.setFrame(saved, display: false)
        } else {
            // Default: bottom-right of main screen
            if let screen = NSScreen.main {
                let sf = screen.visibleFrame
                let w: CGFloat = 420
                let h: CGFloat = 520
                let origin = NSPoint(x: sf.maxX - w - 20, y: sf.minY + 20)
                window.setFrame(NSRect(origin: origin, size: NSSize(width: w, height: h)), display: false)
            }
        }
    }
}

// MARK: - FloatingPanel subclass (click-through background)

class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
