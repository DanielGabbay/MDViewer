import Foundation
import AppKit

enum AppLanguage: String, CaseIterable {
    case hebrew = "he"
    case english = "en"

    var displayName: String {
        switch self {
        case .hebrew:  return "עברית"
        case .english: return "English"
        }
    }
}

class LocalizationManager {
    static let shared = LocalizationManager()

    var language: AppLanguage {
        didSet {
            PreferencesManager.shared.language = language.rawValue
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }

    private init() {
        let saved = PreferencesManager.shared.language
        language = AppLanguage(rawValue: saved) ?? .hebrew
    }

    func str(_ key: StringKey) -> String {
        return key.string(for: language)
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("MDViewer.languageChanged")
}

// ─── All UI strings ───────────────────────────────────────────────────────────
enum StringKey {
    // Settings window
    case settingsTitle
    case settingsWindowTitle
    case clipboardMonitor
    case alwaysOnTop
    case showOnlyMarkdown
    case keyboard
    case opacity
        case language
        case soon
        case versionLine
        case showInDock

    // Toolbar / main window
    case appName
    case emptyPlaceholder
    case notMarkdown

    // Menubar menu
    case menuShow
    case menuHide
    case menuSettings
    case menuQuit

    func string(for lang: AppLanguage) -> String {
        switch (self, lang) {

        // ── Settings window ──────────────────────────────────────────────────
        case (.settingsTitle, .hebrew):         return "⚙️  הגדרות MD Viewer"
        case (.settingsTitle, .english):        return "⚙️  MD Viewer Settings"

        case (.settingsWindowTitle, .hebrew):   return "MD Viewer — הגדרות"
        case (.settingsWindowTitle, .english):  return "MD Viewer — Settings"

        case (.clipboardMonitor, .hebrew):      return "עקוב אחר לוח העריכה אוטומטית"
        case (.clipboardMonitor, .english):     return "Auto-monitor clipboard"

        case (.alwaysOnTop, .hebrew):           return "תמיד מעל שאר החלונות"
        case (.alwaysOnTop, .english):          return "Always on top"

        case (.showOnlyMarkdown, .hebrew):      return "הצג רק כשהטקסט הוא Markdown (אחרת — הצג הכל)"
        case (.showOnlyMarkdown, .english):     return "Show only when text is Markdown (otherwise show all)"

        case (.keyboard, .hebrew):              return "קיצור מקלדת:"
        case (.keyboard, .english):             return "Keyboard shortcut:"

        case (.opacity, .hebrew):               return "שקיפות חלונית:"
        case (.opacity, .english):              return "Window opacity:"

        case (.language, .hebrew):              return "שפה:"
        case (.language, .english):             return "Language:"

        case (.soon, .hebrew):                  return "שנה (בקרוב)"
        case (.soon, .english):                 return "Change (soon)"

        case (.versionLine, .hebrew):           return "MD Viewer v1.0  •  Daniel Gabbay  •  2025"
        case (.versionLine, .english):          return "MD Viewer v1.0  •  Daniel Gabbay  •  2025"

        case (.showInDock, .hebrew):            return "הצג בDock"
        case (.showInDock, .english):           return "Show in Dock"

        // ── Main window ───────────────────────────────────────────────────────
        case (.appName, _):                     return "MD Viewer"

        case (.emptyPlaceholder, .hebrew):
            return "<p style='color:#666;text-align:center;margin-top:40px;font-size:14px;direction:rtl'>העתק טקסט Markdown ללוח העריכה<br>והוא יוצג כאן 📋</p>"
        case (.emptyPlaceholder, .english):
            return "<p style='color:#666;text-align:center;margin-top:40px;font-size:14px'>Copy any Markdown text to clipboard<br>and it will appear here 📋</p>"

        case (.notMarkdown, .hebrew):
            return "<p style='color:#555;text-align:center;margin-top:40px;font-size:13px;direction:rtl'>הטקסט אינו Markdown</p>"
        case (.notMarkdown, .english):
            return "<p style='color:#555;text-align:center;margin-top:40px;font-size:13px'>Text is not Markdown</p>"

        // ── Menubar ───────────────────────────────────────────────────────────
        case (.menuShow, .hebrew):              return "הצג חלונית"
        case (.menuShow, .english):             return "Show Panel"

        case (.menuHide, .hebrew):              return "הסתר חלונית"
        case (.menuHide, .english):             return "Hide Panel"

        case (.menuSettings, .hebrew):          return "הגדרות…"
        case (.menuSettings, .english):         return "Settings…"

        case (.menuQuit, .hebrew):              return "יציאה"
        case (.menuQuit, .english):             return "Quit"
        }
    }
}

// Convenience global shorthand
func L(_ key: StringKey) -> String {
    LocalizationManager.shared.str(key)
}
