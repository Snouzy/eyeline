import SwiftUI

@main
struct EyelineApp: App {
    @State private var store = ScriptStore()

    var body: some Scene {
        WindowGroup {
            ScriptListView()
                .environment(store)
        }
    }
}
