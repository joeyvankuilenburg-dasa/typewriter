import SwiftUI
import AppKit

struct ContentView: View {
    @Binding var document: MarkdownDocument

    var body: some View {
        TypewriterEditor(text: $document.text)
            .frame(minWidth: 500, minHeight: 400)
            .background(WindowConfigurator())
            .ignoresSafeArea()
    }
}

private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            // Transparent title bar that blends into the editor background
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.backgroundColor = NSColor(srgbRed: 0.969, green: 0.969, blue: 0.969, alpha: 1)
            window.isMovableByWindowBackground = true
            window.titleVisibility = .visible
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
