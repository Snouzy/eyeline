import SwiftUI

struct ScriptListView: View {
    @Environment(ScriptStore.self) private var store
    @AppStorage(Setting.wordsPerMinuteKey) private var wordsPerMinute = Setting.wordsPerMinute
    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(store.scripts) { script in
                    NavigationLink(value: script.id) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Layout.title(script.text) ?? "Sans titre")
                                .lineLimit(1)
                            Text(Layout.summary(wordCount: Layout.wordCount(script.text), wordsPerMinute: wordsPerMinute))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    let ids = offsets.map { store.scripts[$0].id }
                    for id in ids {
                        store.delete(id: id)
                    }
                }
            }
            .overlay {
                if store.scripts.isEmpty {
                    ContentUnavailableView(
                        "Aucun script", systemImage: "text.alignleft",
                        description: Text("Copie ton texte, puis touche Coller."))
                }
            }
            .navigationTitle("Scripts")
            .navigationDestination(for: String.self) { id in
                EditorView(id: id)
            }
            .toolbar {
                ToolbarItem {
                    PasteButton(payloadType: String.self) { strings in
                        open(store.create(text: strings.joined(separator: "\n")))
                    }
                }
                ToolbarItem {
                    Button("Nouveau script", systemImage: "plus") {
                        open(store.create())
                    }
                }
            }
            .alert("Erreur", isPresented: isShowingError) {
                Button("OK") {}
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding {
            store.errorMessage != nil
        } set: { isShown in
            if !isShown {
                store.errorMessage = nil
            }
        }
    }

    private func open(_ script: Script?) {
        guard let script else { return }
        path.append(script.id)
    }
}
