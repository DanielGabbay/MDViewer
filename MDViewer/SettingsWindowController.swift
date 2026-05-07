import AppKit

class SettingsWindowController: NSWindowController {

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L(.settingsWindowTitle)
        window.center()
        self.init(window: window)
        setupContent()

        // Rebuild UI when language changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onLanguageChanged),
            name: .languageChanged,
            object: nil
        )
    }

    @objc private func onLanguageChanged() {
        window?.title = L(.settingsWindowTitle)
        // Rebuild content
        window?.contentView?.subviews.forEach { $0.removeFromSuperview() }
        setupContent()
    }

    private func setupContent() {
        guard let contentView = window?.contentView else { return }
        let prefs = PreferencesManager.shared
        let isRTL = LocalizationManager.shared.language == .hebrew

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 16
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        stack.alignment = isRTL ? .trailing : .leading
        contentView.addSubview(stack)

        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
        ])

        // Title
        let titleLabel = NSTextField(labelWithString: L(.settingsTitle))
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.alignment = isRTL ? .right : .left
        stack.addArrangedSubview(titleLabel)

        stack.addArrangedSubview(makeSeparator())

        // Clipboard monitor toggle
        let clipboardCheck = makeCheckbox(
            title: L(.clipboardMonitor),
            isOn: prefs.autoMonitorClipboard,
            action: #selector(toggleClipboard)
        )
        stack.addArrangedSubview(clipboardCheck)

        // Always on top
        let topCheck = makeCheckbox(
            title: L(.alwaysOnTop),
            isOn: prefs.alwaysOnTop,
            action: #selector(toggleAlwaysOnTop)
        )
        stack.addArrangedSubview(topCheck)

        // Show only markdown
        let mdOnlyCheck = makeCheckbox(
            title: L(.showOnlyMarkdown),
            isOn: prefs.showOnlyMarkdown,
            action: #selector(toggleMarkdownOnly)
        )
        stack.addArrangedSubview(mdOnlyCheck)

        stack.addArrangedSubview(makeSeparator())

        // Hotkey row
        let hotkeyRow = makeRow(label: L(.keyboard))
        let hotkeyValue = NSTextField(labelWithString: "⌘ ⇧ M")
        hotkeyValue.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        hotkeyValue.textColor = .secondaryLabelColor
        let changeBtn = NSButton(title: L(.soon), target: nil, action: nil)
        changeBtn.isEnabled = false
        hotkeyRow.addArrangedSubview(hotkeyValue)
        hotkeyRow.addArrangedSubview(changeBtn)
        stack.addArrangedSubview(hotkeyRow)

        // Opacity row
        let opacityRow = makeRow(label: L(.opacity))
        let slider = NSSlider(value: prefs.windowOpacity, minValue: 0.3, maxValue: 1.0, target: self, action: #selector(opacityChanged(_:)))
        slider.controlSize = .small
        slider.widthAnchor.constraint(equalToConstant: 120).isActive = true
        let opacityValueLabel = NSTextField(labelWithString: "\(Int(prefs.windowOpacity * 100))%")
        opacityValueLabel.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        opacityValueLabel.tag = 99
        opacityRow.addArrangedSubview(slider)
        opacityRow.addArrangedSubview(opacityValueLabel)
        stack.addArrangedSubview(opacityRow)

        // Language row
        let langRow = makeRow(label: L(.language))
        let langSelector = NSSegmentedControl(
            labels: AppLanguage.allCases.map { $0.displayName },
            trackingMode: .selectOne,
            target: self,
            action: #selector(languageChanged(_:))
        )
        let currentLang = LocalizationManager.shared.language
        langSelector.selectedSegment = AppLanguage.allCases.firstIndex(of: currentLang) ?? 0
        langRow.addArrangedSubview(langSelector)
        stack.addArrangedSubview(langRow)

        stack.addArrangedSubview(makeSeparator())

        // Version
        let version = NSTextField(labelWithString: L(.versionLine))
        version.font = NSFont.systemFont(ofSize: 11)
        version.textColor = .tertiaryLabelColor
        version.alignment = isRTL ? .right : .left
        stack.addArrangedSubview(version)
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private func makeCheckbox(title: String, isOn: Bool, action: Selector) -> NSButton {
        let btn = NSButton(checkboxWithTitle: title, target: self, action: action)
        btn.state = isOn ? .on : .off
        return btn
    }

    private func makeSeparator() -> NSBox {
        let sep = NSBox()
        sep.boxType = .separator
        return sep
    }

    /// Creates a horizontal stack with a label of fixed width, direction-aware.
    private func makeRow(label: String) -> NSStackView {
        let isRTL = LocalizationManager.shared.language == .hebrew
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 8
        if isRTL {
            row.userInterfaceLayoutDirection = .rightToLeft
        }
        let lbl = NSTextField(labelWithString: label)
        lbl.font = NSFont.systemFont(ofSize: 13)
        lbl.alignment = isRTL ? .right : .left
        lbl.widthAnchor.constraint(equalToConstant: 130).isActive = true
        row.addArrangedSubview(lbl)
        return row
    }

    // ── Actions ───────────────────────────────────────────────────────────────

    @objc func toggleClipboard(_ sender: NSButton) {
        PreferencesManager.shared.autoMonitorClipboard = sender.state == .on
        (NSApp.delegate as? AppDelegate)?.toggleClipboardMonitor()
    }

    @objc func toggleAlwaysOnTop(_ sender: NSButton) {
        PreferencesManager.shared.alwaysOnTop = sender.state == .on
        (NSApp.delegate as? AppDelegate)?.floatingWindowController?.window?.level =
            PreferencesManager.shared.alwaysOnTop ? .floating : .normal
    }

    @objc func toggleMarkdownOnly(_ sender: NSButton) {
        PreferencesManager.shared.showOnlyMarkdown = sender.state == .on
    }

    @objc func opacityChanged(_ sender: NSSlider) {
        let val = sender.doubleValue
        PreferencesManager.shared.windowOpacity = val
        (NSApp.delegate as? AppDelegate)?.floatingWindowController?.window?.alphaValue = val
        if let label = window?.contentView?.viewWithTag(99) as? NSTextField {
            label.stringValue = "\(Int(val * 100))%"
        }
    }

    @objc func languageChanged(_ sender: NSSegmentedControl) {
        let selected = sender.selectedSegment
        let lang = AppLanguage.allCases[selected]
        LocalizationManager.shared.language = lang
    }
}
