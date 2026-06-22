import SwiftUI
import AppKit

// Maximum content column width in points
private let columnWidth: CGFloat = 680
// Horizontal padding inside the text container
private let horizontalPadding: CGFloat = 48
// Body font size
private let bodySize: CGFloat = 17

struct TypewriterEditor: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let textView = buildTextView(coordinator: context.coordinator)
        context.coordinator.textView = textView

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = TypewriterTheme.background

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        // Only sync when the change came from outside (e.g. undo or file reload)
        if textView.string != text {
            let selected = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selected
            context.coordinator.styler.styleAll(in: textView.textStorage!)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Build text view

    private func buildTextView(coordinator: Coordinator) -> NSTextView {
        let tv = NSTextView()

        tv.isRichText = false
        tv.allowsUndo = true
        tv.isEditable = true
        tv.isSelectable = true

        // Disable macOS smart substitutions so markdown stays literal
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticTextReplacementEnabled = false
        tv.isAutomaticSpellingCorrectionEnabled = false
        tv.isContinuousSpellCheckingEnabled = false
        tv.isGrammarCheckingEnabled = false

        // Find bar
        tv.usesFindBar = true
        tv.isIncrementalSearchingEnabled = true

        // Colors
        tv.drawsBackground = true
        tv.backgroundColor = TypewriterTheme.background
        tv.insertionPointColor = TypewriterTheme.ink
        tv.selectedTextAttributes = [
            .backgroundColor: TypewriterTheme.selection
        ]

        // Base font & paragraph style applied to whole document
        tv.font = TypewriterTheme.bodyFont
        tv.defaultParagraphStyle = TypewriterTheme.bodyParagraphStyle
        tv.typingAttributes = TypewriterTheme.bodyAttributes

        // Column layout: constrain text container width
        tv.textContainer?.widthTracksTextView = false
        tv.textContainer?.containerSize = NSSize(width: columnWidth, height: CGFloat.greatestFiniteMagnitude)
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.autoresizingMask = [.width]

        // Generous top/bottom padding; left/right padding is handled by centering the column
        tv.textContainerInset = NSSize(width: horizontalPadding, height: 60)

        // Delegate
        tv.delegate = coordinator
        tv.textStorage?.delegate = coordinator

        return tv
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
        var parent: TypewriterEditor
        var textView: NSTextView?
        let styler = MarkdownStyler()
        private var isApplyingAttributes = false

        init(_ parent: TypewriterEditor) {
            self.parent = parent
        }

        // Sync text back to the binding
        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
        }

        // Re-style the affected paragraph range after every edit
        func textStorage(
            _ textStorage: NSTextStorage,
            didProcessEditing editedMask: NSTextStorageEditActions,
            range editedRange: NSRange,
            changeInLength delta: Int
        ) {
            guard !isApplyingAttributes,
                  editedMask.contains(.editedCharacters)
            else { return }

            isApplyingAttributes = true
            textStorage.beginEditing()
            styler.styleAffectedParagraphs(in: textStorage, editedRange: editedRange)
            textStorage.endEditing()
            isApplyingAttributes = false
        }
    }
}

// MARK: - Center-column frame logic

// We want the NSTextView to sit in a centered column regardless of window width.
// We achieve this by making the scroll view's document view wider than the column,
// and letting textContainerInset + a fixed containerSize center the text.
// The scroll view's clip view handles horizontal centering via constraints set below.

extension NSScrollView {
    // Called automatically when the scroll view is laid out
    override open func layout() {
        super.layout()
        guard let tv = documentView as? NSTextView else { return }

        // Keep the text view at least as wide as the scroll view so it fills it
        let totalWidth = max(bounds.width, columnWidth + horizontalPadding * 2)
        tv.frame = NSRect(x: 0, y: 0, width: totalWidth, height: tv.frame.height)

        // Center the text container horizontally within the text view
        let padding = max((bounds.width - columnWidth) / 2, horizontalPadding)
        tv.textContainerInset = NSSize(width: padding, height: 60)
        tv.textContainer?.containerSize = NSSize(
            width: columnWidth,
            height: CGFloat.greatestFiniteMagnitude
        )
    }
}
