import AppKit

// Applies visual attributes to markdown source while keeping all characters visible.
// Only monospace fonts are used so the typewriter feel is preserved.
final class MarkdownStyler {

    // MARK: - Public interface

    func styleAll(in storage: NSTextStorage) {
        let full = NSRange(location: 0, length: storage.length)
        applyStyles(in: storage, range: full)
    }

    func styleAffectedParagraphs(in storage: NSTextStorage, editedRange: NSRange) {
        let string = storage.string as NSString
        let paragraphRange = string.paragraphRange(for: editedRange)
        applyStyles(in: storage, range: paragraphRange)
    }

    // MARK: - Core styling pass

    private func applyStyles(in storage: NSTextStorage, range: NSRange) {
        guard storage.length > 0, range.length > 0 else { return }

        let safeRange = NSRange(
            location: min(range.location, storage.length),
            length: min(range.length, storage.length - min(range.location, storage.length))
        )
        guard safeRange.length > 0 else { return }

        // Reset to body style
        storage.setAttributes(TypewriterTheme.bodyAttributes, range: safeRange)

        let string = storage.string as NSString
        // Iterate paragraph by paragraph
        var pos = safeRange.location
        let end = NSMaxRange(safeRange)

        while pos < end {
            let paraRange = string.paragraphRange(for: NSRange(location: pos, length: 0))
            let line = string.substring(with: paraRange)
            styleOneParagraph(line: line, paraRange: paraRange, in: storage)
            pos = NSMaxRange(paraRange)
            if pos <= paraRange.location { break } // guard against zero-length loop
        }
    }

    // MARK: - Per-paragraph dispatch

    private func styleOneParagraph(line: String, paraRange: NSRange, in storage: NSTextStorage) {
        // ATX headings: # to ######
        if let (level, markerLen) = headingLevel(line) {
            applyHeading(level: level, markerLen: markerLen, range: paraRange, in: storage)
            return
        }

        // Fenced code block line (``` or ~~~)
        if line.hasPrefix("```") || line.hasPrefix("~~~") {
            storage.addAttribute(.foregroundColor, value: TypewriterTheme.dimmed, range: paraRange)
            return
        }

        // Blockquote
        if line.hasPrefix(">") {
            storage.addAttribute(.foregroundColor, value: TypewriterTheme.dimmed, range: paraRange)
            // Then style inline spans within
            applyInlineStyles(in: line, paraRange: paraRange, storage: storage)
            return
        }

        // Thematic break
        if isThematicBreak(line) {
            storage.addAttribute(.foregroundColor, value: TypewriterTheme.dimmed, range: paraRange)
            return
        }

        // Regular paragraph — apply inline styles
        applyInlineStyles(in: line, paraRange: paraRange, storage: storage)
    }

    // MARK: - Heading

    private func headingLevel(_ line: String) -> (Int, Int)? {
        var count = 0
        for ch in line {
            if ch == "#" { count += 1 } else { break }
        }
        guard count >= 1, count <= 6 else { return nil }
        let afterHashes = line.dropFirst(count)
        guard afterHashes.first == " " || afterHashes.isEmpty else { return nil }
        return (count, count + (afterHashes.isEmpty ? 0 : 1))
    }

    private func applyHeading(level: Int, markerLen: Int, range: NSRange, in storage: NSTextStorage) {
        let sizes: [Int: CGFloat] = [1: 26, 2: 24, 3: 22, 4: 21, 5: 20, 6: 20]
        let size = sizes[level] ?? 17
        let weight: NSFont.Weight = level <= 2 ? .bold : .semibold

        let ps = TypewriterTheme.headingParagraphStyle.mutableCopy() as! NSMutableParagraphStyle

        storage.addAttributes([
            .font: TypewriterTheme.font(size: size, weight: weight),
            .foregroundColor: TypewriterTheme.ink,
            .paragraphStyle: ps
        ], range: range)

        // Dim the leading # markers
        if markerLen > 0 {
            let markerRange = NSRange(location: range.location, length: min(markerLen, range.length))
            storage.addAttribute(.foregroundColor, value: TypewriterTheme.dimmed, range: markerRange)
        }
    }

    // MARK: - Inline styles

    private func applyInlineStyles(in line: String, paraRange: NSRange, storage: NSTextStorage) {
        applyInlineCode(in: line, paraRange: paraRange, storage: storage)
        applyBoldItalic(in: line, paraRange: paraRange, storage: storage)
    }

    // Inline code: `code`
    private func applyInlineCode(in line: String, paraRange: NSRange, storage: NSTextStorage) {
        let nsLine = line as NSString
        var searchStart = 0
        while searchStart < nsLine.length {
            let openRange = nsLine.range(of: "`", range: NSRange(location: searchStart, length: nsLine.length - searchStart))
            guard openRange.location != NSNotFound else { break }
            let afterOpen = NSMaxRange(openRange)
            let closeRange = nsLine.range(of: "`", range: NSRange(location: afterOpen, length: nsLine.length - afterOpen))
            guard closeRange.location != NSNotFound else { break }

            let spanRange = NSRange(
                location: paraRange.location + openRange.location,
                length: NSMaxRange(closeRange) - openRange.location
            )
            if NSMaxRange(spanRange) <= NSMaxRange(paraRange) {
                storage.addAttribute(.foregroundColor, value: TypewriterTheme.codeTint, range: spanRange)
            }
            searchStart = NSMaxRange(closeRange)
        }
    }

    // Bold: **text** or __text__   Italic: *text* or _text_   BoldItalic: ***text***
    private func applyBoldItalic(in line: String, paraRange: NSRange, storage: NSTextStorage) {
        let patterns: [(String, NSFont.Weight, Bool)] = [
            ("\\*\\*\\*(.+?)\\*\\*\\*", .bold, true),
            ("___(.+?)___",             .bold, true),
            ("\\*\\*(.+?)\\*\\*",       .bold, false),
            ("__(.+?)__",               .bold, false),
            ("\\*(.+?)\\*",             .regular, true),
            ("_(.+?)_",                 .regular, true),
        ]
        for (pattern, weight, italic) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
            let nsLine = line as NSString
            let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
            for match in matches {
                let spanRange = NSRange(
                    location: paraRange.location + match.range.location,
                    length: match.range.length
                )
                guard NSMaxRange(spanRange) <= NSMaxRange(paraRange) else { continue }

                var descriptor = TypewriterTheme.bodyFont.fontDescriptor
                var traits = NSFontDescriptor.SymbolicTraits()
                if weight == .bold { traits.insert(.bold) }
                if italic { traits.insert(.italic) }
                descriptor = descriptor.withSymbolicTraits(traits)
                if let styled = NSFont(descriptor: descriptor, size: TypewriterTheme.bodyFont.pointSize) {
                    storage.addAttribute(.font, value: styled, range: spanRange)
                }

                // Dim the marker characters (everything outside the inner capture group)
                let outerRange = match.range
                let innerRange = match.range(at: 1)
                if innerRange.location != NSNotFound {
                    // prefix markers (absolute positions in storage)
                    let prefixRange = NSRange(
                        location: paraRange.location + outerRange.location,
                        length: innerRange.location - outerRange.location
                    )
                    // suffix markers
                    let suffixStart = NSMaxRange(innerRange)
                    let suffixRange = NSRange(
                        location: paraRange.location + suffixStart,
                        length: NSMaxRange(outerRange) - suffixStart
                    )
                    for r in [prefixRange, suffixRange] where r.length > 0 {
                        if NSMaxRange(r) <= NSMaxRange(spanRange) {
                            storage.addAttribute(.foregroundColor, value: TypewriterTheme.dimmed, range: r)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Thematic break detection

    private func isThematicBreak(_ line: String) -> Bool {
        let stripped = line.filter { !$0.isWhitespace }
        guard stripped.count >= 3 else { return false }
        let chars = Set(stripped)
        return chars.count == 1 && (chars.contains("-") || chars.contains("*") || chars.contains("_"))
    }
}
