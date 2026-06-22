import SwiftUI

@main
struct TypewriterApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    NSDocumentController.shared.newDocument(nil)
                }
                .keyboardShortcut("n")

                Button("Open…") {
                    NSDocumentController.shared.openDocument(nil)
                }
                .keyboardShortcut("o")
            }
        }
    }
}
