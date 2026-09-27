import SwiftUI

struct EditorView: View {
    let id: String
    @Environment(ScriptStore.self) private var store
    @State private var text = ""
    @State private var isReading = false

    var body: some View {
        TextEditor(text: $text)
            .padding(.horizontal)
            .navigationTitle(Layout.title(text) ?? "Sans titre")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Lire", systemImage: "play.fill") {
                    isReading = true
                }
                .disabled(Layout.wordCount(text) == 0)
            }
            .fullScreenCover(isPresented: $isReading) {
                PrompterView(text: text)
            }
            .onAppear {
                text = store.scripts.first { $0.id == id }?.text ?? ""
            }
            .onChange(of: text) {
                store.save(id: id, text: text)
            }
            .onDisappear {
                // "Lire" is disabled without words, so the prompter cover never gets here with an empty text.
                if Layout.wordCount(text) == 0 {
                    store.delete(id: id)
                }
            }
    }
}
