import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument

    var body: some View {
        TypewriterEditor(text: $document.text)
            .frame(minWidth: 500, minHeight: 400)
    }
}
