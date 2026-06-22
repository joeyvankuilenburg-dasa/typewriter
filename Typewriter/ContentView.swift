import SwiftUI
import AppKit

struct ContentView: View {
    @Binding var document: MarkdownDocument

    var body: some View {
        TypewriterEditor(text: $document.text)
            .frame(minWidth: 500, minHeight: 400)
            .background(WindowConfigurator())
    }
}

// Reaches up to the NSWindow and applies macOS-native window chrome settings.
private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // Defer until the view is in the window hierarchy
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.toolbarStyle = .unified
            window.titlebarSeparatorStyle = .automatic
            window.isMovableByWindowBackground = true
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            window.toolbarStyle = .unified
        }
    }
}
