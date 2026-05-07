import AppKit

class ClipboardMonitor {

    var onMarkdownDetected: ((String) -> Void)?
    private var timer: Timer?
    private var lastChangeCount: Int = -1

    func start() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        guard let text = pb.string(forType: .string), !text.isEmpty else { return }

        onMarkdownDetected?(text)  // Always show — renderer will handle detection
    }

    static func isLikelyMarkdown(_ text: String) -> Bool {
        let patterns = [
            #"^#{1,6}\s"#,           // Headers
            #"\*\*[^*]+\*\*"#,       // Bold
            #"\*[^*]+\*"#,           // Italic
            #"^\s*[-*+]\s"#,         // Lists
            #"^\s*\d+\.\s"#,         // Ordered lists
            #"```"#,                  // Code blocks
            #"`[^`]+`"#,             // Inline code
            #"^\s*>"#,               // Blockquote
            #"\[.+\]\(.+\)"#,        // Links
            #"^\s*\|.+\|"#,          // Tables
            #"^---$"#,               // HR
        ]
        let lines = text.components(separatedBy: "\n")
        var matches = 0
        for pattern in patterns {
            for line in lines {
                if line.range(of: pattern, options: .regularExpression) != nil {
                    matches += 1
                    break
                }
            }
        }
        return matches >= 1
    }
}
