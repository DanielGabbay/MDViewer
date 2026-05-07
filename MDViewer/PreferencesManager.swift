import Foundation

class PreferencesManager {

    static let shared = PreferencesManager()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let alwaysOnTop = "alwaysOnTop"
        static let autoMonitorClipboard = "autoMonitorClipboard"
        static let windowFrame = "windowFrame"
        static let hotkey = "hotkey"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let showOnlyMarkdown = "showOnlyMarkdown"
        static let windowOpacity = "windowOpacity"
        static let language = "language"
    }

    var alwaysOnTop: Bool {
        get { defaults.object(forKey: Keys.alwaysOnTop) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.alwaysOnTop) }
    }

    var autoMonitorClipboard: Bool {
        get { defaults.object(forKey: Keys.autoMonitorClipboard) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.autoMonitorClipboard) }
    }

    var showOnlyMarkdown: Bool {
        get { defaults.object(forKey: Keys.showOnlyMarkdown) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Keys.showOnlyMarkdown) }
    }

    var windowOpacity: Double {
        get { defaults.object(forKey: Keys.windowOpacity) as? Double ?? 1.0 }
        set { defaults.set(newValue, forKey: Keys.windowOpacity) }
    }

    var windowFrame: NSRect {
        get {
            guard let data = defaults.data(forKey: Keys.windowFrame),
                  let value = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSValue.self, from: data) else {
                return NSRect(x: 0, y: 0, width: 420, height: 520)
            }
            return value.rectValue
        }
        set {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: NSValue(rect: newValue), requiringSecureCoding: true) {
                defaults.set(data, forKey: Keys.windowFrame)
            }
        }
    }

    var language: String {
        get { defaults.string(forKey: Keys.language) ?? "he" }
        set { defaults.set(newValue, forKey: Keys.language) }
    }

    // Hotkey: default Cmd+Shift+M
    var hotkeyChar: String {
        get { defaults.string(forKey: Keys.hotkey) ?? "m" }
        set { defaults.set(newValue, forKey: Keys.hotkey) }
    }
}

// Make NSRect available
import AppKit
