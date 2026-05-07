import Foundation
import AppKit

struct MarkdownRenderer {

    // MARK: - Main Render

    static func render(_ markdown: String) -> String {
        let isMarkdown = ClipboardMonitor.isLikelyMarkdown(markdown)
        // For plain text (non-markdown), detect direction once at document level
        // so the pre block is rendered correctly. For markdown, each block uses dir="auto".
        let plainDir: String
        if !isMarkdown {
            plainDir = detectDocumentDirection(markdown)
        } else {
            plainDir = "ltr" // unused for markdown path
        }
        let bodyContent = isMarkdown ? convertMarkdownToHTML(markdown) : "<pre class=\"plain\" dir=\"\(plainDir)\">\(escapeHTML(markdown))</pre>"
        let badge = isMarkdown ? "<span class=\"badge md\">MD</span>" : "<span class=\"badge plain\">Plain</span>"

        return """
        <!DOCTYPE html>
        <html lang="auto">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
        \(css())
        </style>
        </head>
        <body>
        <div class="badges">\(badge)</div>
        <div class="content">
        \(bodyContent)
        </div>
        </body>
        </html>
        """
    }

    // MARK: - Document-level direction (used only for plain text)

    /// First-strong heuristic per Unicode UBA P2/P3:
    /// scan characters in order, return direction of first strong directional character.
    private static func detectDocumentDirection(_ text: String) -> String {
        for scalar in text.unicodeScalars {
            let v = scalar.value
            // Strong RTL: Hebrew, Hebrew Extended, Arabic
            if (0x0590...0x05FF).contains(v) ||
               (0xFB1D...0xFB4F).contains(v) ||
               (0x0600...0x06FF).contains(v) { return "rtl" }
            // Strong LTR: Basic Latin letters
            if (0x0041...0x005A).contains(v) || (0x0061...0x007A).contains(v) { return "ltr" }
        }
        return "ltr"
    }

    static func renderEmpty() -> String {
        let placeholder = L(.emptyPlaceholder)
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="UTF-8">
        <style>
        \(css())
        </style>
        </head>
        <body>
        <div class="empty">
        <div class="empty-icon">📋</div>
        \(placeholder)
        </div>
        </body>
        </html>
        """
    }

    // MARK: - Simple Markdown → HTML

    static func convertMarkdownToHTML(_ md: String) -> String {
        var lines = md.components(separatedBy: "\n")
        var html = ""
        var inCodeBlock = false
        var codeLines: [String] = []
        var inBlockquote = false
        var listItems: [String] = []
        var orderedItems: [String] = []
        var tableRows: [[String]] = []
        var inTable = false

        func flushList() {
            if !listItems.isEmpty {
                html += "<ul dir=\"auto\">\n"
                for item in listItems { html += "<li dir=\"auto\">\(inlineFormat(item))</li>\n" }
                html += "</ul>\n"
                listItems.removeAll()
            }
        }
        func flushOrdered() {
            if !orderedItems.isEmpty {
                html += "<ol dir=\"auto\">\n"
                for item in orderedItems { html += "<li dir=\"auto\">\(inlineFormat(item))</li>\n" }
                html += "</ol>\n"
                orderedItems.removeAll()
            }
        }
        func flushBlockquote() {
            if inBlockquote {
                html += "</blockquote>\n"
                inBlockquote = false
            }
        }
        func flushTable() {
            guard !tableRows.isEmpty else { return }
            html += "<table dir=\"auto\">\n"
            let isHeader = tableRows.count > 1 && tableRows[1].allSatisfy({ $0.trimmingCharacters(in: .whitespaces).allSatisfy({ $0 == "-" || $0 == "|" || $0 == ":" || $0 == " " }) })
            for (i, row) in tableRows.enumerated() {
                if isHeader && i == 1 { continue }
                let tag = (isHeader && i == 0) ? "th" : "td"
                html += "<tr>" + row.map { "<\(tag) dir=\"auto\">\(inlineFormat($0))</\(tag)>" }.joined() + "</tr>\n"
            }
            html += "</table>\n"
            tableRows.removeAll()
            inTable = false
        }

        for line in lines {
            // Code block
            if line.hasPrefix("```") {
                if inCodeBlock {
                    inCodeBlock = false
                    let lang = ""
                    html += "<pre><code>\(escapeHTML(codeLines.joined(separator: "\n")))</code></pre>\n"
                    codeLines.removeAll()
                } else {
                    flushList(); flushOrdered(); flushBlockquote(); flushTable()
                    inCodeBlock = true
                }
                continue
            }
            if inCodeBlock { codeLines.append(line); continue }

            // Table
            if line.contains("|") && line.hasPrefix("|") {
                flushList(); flushOrdered(); flushBlockquote()
                inTable = true
                let cells = line.components(separatedBy: "|").dropFirst().dropLast().map {
                    $0.trimmingCharacters(in: .whitespaces)
                }
                tableRows.append(Array(cells))
                continue
            } else if inTable {
                flushTable()
            }

            // HR
            if line.trimmingCharacters(in: .whitespaces) == "---" || line.trimmingCharacters(in: .whitespaces) == "***" {
                flushList(); flushOrdered(); flushBlockquote()
                html += "<hr>\n"; continue
            }

            // Headers
            if let m = line.range(of: #"^(#{1,6})\s+(.*)"#, options: .regularExpression) {
                flushList(); flushOrdered(); flushBlockquote(); flushTable()
                let level = line[m].prefix(while: { $0 == "#" }).count
                let text = line.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression)
                html += "<h\(level) dir=\"auto\">\(inlineFormat(text))</h\(level)>\n"; continue
            }

            // Blockquote
            if line.hasPrefix("> ") {
                flushList(); flushOrdered(); flushTable()
                if !inBlockquote { html += "<blockquote dir=\"auto\">\n"; inBlockquote = true }
                html += "<p dir=\"auto\">\(inlineFormat(String(line.dropFirst(2))))</p>\n"; continue
            } else { flushBlockquote() }

            // Unordered list
            if line.range(of: #"^\s*[-*+]\s+"#, options: .regularExpression) != nil {
                flushOrdered(); flushBlockquote(); flushTable()
                let text = line.replacingOccurrences(of: #"^\s*[-*+]\s+"#, with: "", options: .regularExpression)
                listItems.append(text); continue
            } else { flushList() }

            // Ordered list
            if line.range(of: #"^\s*\d+\.\s+"#, options: .regularExpression) != nil {
                flushList(); flushBlockquote(); flushTable()
                let text = line.replacingOccurrences(of: #"^\s*\d+\.\s+"#, with: "", options: .regularExpression)
                orderedItems.append(text); continue
            } else { flushOrdered() }

            // Empty line
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                html += "<br>\n"; continue
            }

            // Paragraph
            html += "<p dir=\"auto\">\(inlineFormat(line))</p>\n"
        }

        flushList(); flushOrdered(); flushBlockquote(); flushTable()
        if inCodeBlock {
            html += "<pre><code>\(escapeHTML(codeLines.joined(separator: "\n")))</code></pre>\n"
        }

        return html
    }

    // MARK: - Inline formatting

    static func inlineFormat(_ text: String) -> String {
        var t = escapeHTML(text)
        // Bold+Italic
        t = t.replacingOccurrences(of: #"\*\*\*(.+?)\*\*\*"#, with: "<strong><em>$1</em></strong>", options: .regularExpression)
        // Bold
        t = t.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)
        t = t.replacingOccurrences(of: #"__(.+?)__"#, with: "<strong>$1</strong>", options: .regularExpression)
        // Italic
        t = t.replacingOccurrences(of: #"\*(.+?)\*"#, with: "<em>$1</em>", options: .regularExpression)
        t = t.replacingOccurrences(of: #"_(.+?)_"#, with: "<em>$1</em>", options: .regularExpression)
        // Strikethrough
        t = t.replacingOccurrences(of: #"~~(.+?)~~"#, with: "<del>$1</del>", options: .regularExpression)
        // Inline code
        t = t.replacingOccurrences(of: #"`(.+?)`"#, with: "<code>$1</code>", options: .regularExpression)
        // Links
        t = t.replacingOccurrences(of: #"\[(.+?)\]\((.+?)\)"#, with: "<a href=\"$2\">$1</a>", options: .regularExpression)
        return t
    }

    static func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    // MARK: - CSS

    static func css() -> String {
        let isDark = NSApp.effectiveAppearance.name == .darkAqua ||
                     NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        let bg = isDark ? "#1e1e1e" : "#ffffff"
        let fg = isDark ? "#d4d4d4" : "#1a1a1a"
        let codeBg = isDark ? "#2d2d2d" : "#f5f5f5"
        let codeFg = isDark ? "#ce9178" : "#c7254e"
        let borderColor = isDark ? "#444" : "#ddd"
        let blockquoteBorder = isDark ? "#555" : "#ccc"
        let blockquoteBg = isDark ? "#2a2a2a" : "#f9f9f9"
        let linkColor = isDark ? "#4fc1ff" : "#0066cc"
        let badgeMdBg = isDark ? "#264f78" : "#dbeafe"
        let badgeMdFg = isDark ? "#9cdcfe" : "#1d4ed8"
        let badgePlainBg = isDark ? "#3a3a3a" : "#f3f4f6"
        let badgePlainFg = isDark ? "#aaa" : "#666"

        return """
        * { box-sizing: border-box; margin: 0; padding: 0; }
        html, body {
            background: \(bg);
            color: \(fg);
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            font-size: 14px;
            line-height: 1.65;
            padding: 0;
        }
        .badges {
            position: sticky;
            top: 0;
            padding: 4px 12px;
            background: \(bg);
            border-bottom: 1px solid \(borderColor);
            display: flex;
            gap: 6px;
            z-index: 10;
        }
        .badge {
            font-size: 10px;
            font-weight: 600;
            padding: 2px 6px;
            border-radius: 4px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .badge.md { background: \(badgeMdBg); color: \(badgeMdFg); }
        .badge.plain { background: \(badgePlainBg); color: \(badgePlainFg); }
        .content {
            padding: 14px 16px;
        }
        h1, h2, h3, h4, h5, h6 {
            margin: 0.8em 0 0.4em;
            font-weight: 600;
            line-height: 1.3;
        }
        h1 { font-size: 1.6em; }
        h2 { font-size: 1.35em; }
        h3 { font-size: 1.15em; }
        p { margin: 0.5em 0; }
        strong { font-weight: 700; }
        em { font-style: italic; }
        del { text-decoration: line-through; opacity: 0.7; }
        code {
            font-family: 'SF Mono', 'Menlo', monospace;
            font-size: 0.88em;
            background: \(codeBg);
            color: \(codeFg);
            padding: 1px 4px;
            border-radius: 3px;
        }
        pre {
            background: \(codeBg);
            border-radius: 6px;
            padding: 12px 14px;
            overflow-x: auto;
            margin: 0.8em 0;
            font-size: 0.88em;
            direction: ltr;
            text-align: left;
        }
        pre code {
            background: none;
            color: \(fg);
            padding: 0;
        }
        pre.plain {
            color: \(fg);
            white-space: pre-wrap;
            word-break: break-word;
        }
        ul, ol {
            padding-left: 1.5em;
            margin: 0.5em 0;
        }
        li { margin: 0.2em 0; }
        blockquote {
            border-left: 3px solid \(blockquoteBorder);
            background: \(blockquoteBg);
            padding: 8px 14px;
            margin: 0.8em 0;
            border-radius: 0 4px 4px 0;
        }
        hr {
            border: none;
            border-top: 1px solid \(borderColor);
            margin: 1em 0;
        }
        a { color: \(linkColor); text-decoration: none; }
        a:hover { text-decoration: underline; }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 0.8em 0;
            font-size: 0.92em;
        }
        th, td {
            border: 1px solid \(borderColor);
            padding: 6px 10px;
            text-align: inherit;
        }
        th {
            background: \(codeBg);
            font-weight: 600;
        }
        tr:nth-child(even) { background: \(isDark ? "#252525" : "#f9f9f9"); }
        .empty {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100vh;
            color: \(isDark ? "#555" : "#bbb");
            gap: 8px;
            text-align: center;
        }
        .empty-icon { font-size: 2em; }
        .empty p { font-size: 0.9em; line-height: 1.7; }
        """
    }
}
