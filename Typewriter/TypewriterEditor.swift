import SwiftUI
import AppKit

private let columnWidth: CGFloat = 680
private let minHorizontalPadding: CGFloat = 48
private let verticalPadding: CGFloat = 60
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

        // Observe scroll view frame changes to keep the column centered
        scrollView.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.scrollViewFrameDidChange(_:)),
            name: NSView.frameDidChangeNotification,
            object: scrollView
        )

        // Center the column once the scroll view has been laid out
        DispatchQueue.main.async {
            context.coordinator.centerColumn(textView: textView, in: scrollView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        // Re-center on every SwiftUI update pass (e.g. window resize via SwiftUI)
        context.coordinator.centerColumn(textView: textView, in: scrollView)
        if textView.string != text {
            let selected = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selected
            context.coordinator.styler.styleAll(in: textView.textStorage!)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - Build text view

    private func buildTextView(coordinator: Coordinator) -> NSTextView {
        let tv = NSTextView()

        tv.isRichText = false
        tv.allowsUndo = true
        tv.isEditable = true
        tv.isSelectable = true

        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticTextReplacementEnabled = false
        tv.isAutomaticSpellingCorrectionEnabled = false
        tv.isContinuousSpellCheckingEnabled = false
        tv.isGrammarCheckingEnabled = false

        tv.usesFindBar = true
        tv.isIncrementalSearchingEnabled = true

        tv.drawsBackground = true
        tv.backgroundColor = TypewriterTheme.background
        tv.insertionPointColor = TypewriterTheme.ink
        tv.selectedTextAttributes = [.backgroundColor: TypewriterTheme.selection]

        tv.font = TypewriterTheme.bodyFont
        tv.defaultParagraphStyle = TypewriterTheme.bodyParagraphStyle
        tv.typingAttributes = TypewriterTheme.bodyAttributes

        // Fixed-width text container; centering is done via textContainerInset
        tv.textContainer?.widthTracksTextView = false
        tv.textContainer?.containerSize = NSSize(width: columnWidth, height: .greatestFiniteMagnitude)
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.autoresizingMask = [.width]

        tv.textContainerInset = NSSize(width: minHorizontalPadding, height: verticalPadding)

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

        // Keep the column centered when the scroll view is resized
        @objc func scrollViewFrameDidChange(_ notification: Notification) {
            guard let scrollView = notification.object as? NSScrollView,
                  let tv = scrollView.documentView as? NSTextView else { return }
            centerColumn(textView: tv, in: scrollView)
        }

        func centerColumn(textView: NSTextView, in scrollView: NSScrollView) {
            let availableWidth = scrollView.contentSize.width
            let horizontalInset = max((availableWidth - columnWidth) / 2, minHorizontalPadding)
            textView.textContainerInset = NSSize(width: horizontalInset, height: verticalPadding)

            // The text view must be at least as wide as the scroll view so it
            // fills the background; the text container stays at columnWidth.
            var frame = textView.frame
            frame.size.width = availableWidth
            textView.frame = frame
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
        }

        func textStorage(
            _ textStorage: NSTextStorage,
            didProcessEditing editedMask: NSTextStorageEditActions,
            range editedRange: NSRange,
            changeInLength delta: Int
        ) {
            guard !isApplyingAttributes,
                  editedMask.contains(.editedCharacters) else { return }

            isApplyingAttributes = true
            textStorage.beginEditing()
            styler.styleAffectedParagraphs(in: textStorage, editedRange: editedRange)
            textStorage.endEditing()
            isApplyingAttributes = false
        }
    }
}
