import AppKit

enum TypewriterTheme {
    // MARK: - Colors
    static let background = NSColor(srgbRed: 0.980, green: 0.980, blue: 0.973, alpha: 1) // #FAFAF8
    static let ink        = NSColor(srgbRed: 0.102, green: 0.102, blue: 0.102, alpha: 1) // #1A1A1A
    static let dimmed     = NSColor(srgbRed: 0.60,  green: 0.60,  blue: 0.60,  alpha: 1) // ~40% gray
    static let codeTint   = NSColor(srgbRed: 0.20,  green: 0.44,  blue: 0.70,  alpha: 1) // subtle blue
    static let selection  = NSColor(srgbRed: 0.82,  green: 0.88,  blue: 0.95,  alpha: 1)

    // MARK: - Fonts
    static let bodyFont = NSFont.monospacedSystemFont(ofSize: 17, weight: .regular)

    static func font(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        NSFont.monospacedSystemFont(ofSize: size, weight: weight)
    }

    // MARK: - Paragraph styles
    static let bodyParagraphStyle: NSMutableParagraphStyle = {
        let ps = NSMutableParagraphStyle()
        ps.lineHeightMultiple = 1.55
        ps.paragraphSpacing = 4
        return ps
    }()

    static let headingParagraphStyle: NSMutableParagraphStyle = {
        let ps = NSMutableParagraphStyle()
        ps.lineHeightMultiple = 1.3
        ps.paragraphSpacingBefore = 16
        ps.paragraphSpacing = 6
        return ps
    }()

    // MARK: - Attribute dictionaries
    static var bodyAttributes: [NSAttributedString.Key: Any] {
        [
            .font: bodyFont,
            .foregroundColor: ink,
            .paragraphStyle: bodyParagraphStyle
        ]
    }
}
