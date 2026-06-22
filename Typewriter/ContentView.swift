import SwiftUI
import AppKit

struct ContentView: View {
    @Binding var document: MarkdownDocument

    var body: some View {
        TypewriterEditor(text: $document.text)
            .frame(minWidth: 500, minHeight: 400)
            .ignoresSafeArea()
            .background(WindowConfigurator())
    }
}

private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            let bg = NSColor(srgbRed: 0.969, green: 0.969, blue: 0.969, alpha: 1)
            window.backgroundColor = bg
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            // Remove the separator line under the title bar
            window.titlebarSeparatorStyle = .none
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
