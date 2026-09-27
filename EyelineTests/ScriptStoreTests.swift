import Foundation
import Testing
@testable import Eyeline

struct ScriptStoreTests {
    private let folder: URL
    // 2026-09-27 14:03:21 in the time zone of the test machine, as the file names use it.
    private let date = Calendar.current.date(
        from: DateComponents(year: 2026, month: 9, day: 27, hour: 14, minute: 3, second: 21))!

    init() throws {
        folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    private func makeStore() -> ScriptStore {
        ScriptStore(folder: folder, now: { date })
    }

    private func contents(of name: String) throws -> String {
        try String(contentsOf: folder.appending(path: name), encoding: .utf8)
    }

    @Test func createWritesAFileNamedAfterTheDate() throws {
        let store = makeStore()
        let script = try #require(store.create(text: "Bonjour"))
        #expect(script.id == "2026-09-27 14.03.21.txt")
        #expect(try contents(of: script.id) == "Bonjour")
        #expect(store.scripts.map(\.id) == [script.id])
    }

    @Test func scriptsMadeInTheSameSecondGetANumber() {
        let store = makeStore()
        let ids = (1...3).compactMap { _ in store.create()?.id }
        #expect(ids == ["2026-09-27 14.03.21.txt", "2026-09-27 14.03.21 2.txt", "2026-09-27 14.03.21 3.txt"])
    }

    @Test func listShowsTheLastModifiedFirst() throws {
        for (name, age) in [("old.txt", 100.0), ("new.txt", 10.0)] {
            let url = folder.appending(path: name)
            try "x".write(to: url, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes(
                [.modificationDate: Date.now.addingTimeInterval(-age)], ofItemAtPath: url.path)
        }
        #expect(makeStore().scripts.map(\.id) == ["new.txt", "old.txt"])
    }

    @Test func saveWritesTheTextAndMovesTheScriptToTheTop() throws {
        let store = makeStore()
        let first = try #require(store.create(text: "un"))
        let second = try #require(store.create(text: "deux"))
        store.save(id: first.id, text: "un modifié")
        #expect(try contents(of: first.id) == "un modifié")
        #expect(store.scripts.map(\.id) == [first.id, second.id])
    }

    @Test func saveWithTheSameTextDoesNotMoveTheScript() throws {
        let store = makeStore()
        let first = try #require(store.create(text: "un"))
        let second = try #require(store.create(text: "deux"))
        store.save(id: first.id, text: "un")
        #expect(store.scripts.map(\.id) == [second.id, first.id])
    }

    @Test func deleteRemovesTheFile() throws {
        let store = makeStore()
        let script = try #require(store.create(text: "à supprimer"))
        store.delete(id: script.id)
        #expect(store.scripts.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: folder.appending(path: script.id).path))
    }

    @Test func listSkipsUnreadableFilesAndOtherTypes() throws {
        try Data([0xFF, 0xFE, 0xFD]).write(to: folder.appending(path: "binaire.txt"))
        try "note".write(to: folder.appending(path: "note.md"), atomically: true, encoding: .utf8)
        try "script".write(to: folder.appending(path: "script.txt"), atomically: true, encoding: .utf8)
        #expect(makeStore().scripts.map(\.id) == ["script.txt"])
    }

    @Test func listDeletesEmptyScripts() throws {
        try " \n ".write(to: folder.appending(path: "vide.txt"), atomically: true, encoding: .utf8)
        try "script".write(to: folder.appending(path: "script.txt"), atomically: true, encoding: .utf8)
        #expect(makeStore().scripts.map(\.id) == ["script.txt"])
        #expect(!FileManager.default.fileExists(atPath: folder.appending(path: "vide.txt").path))
    }

    @Test func missingFolderGivesAnErrorMessage() {
        let store = ScriptStore(folder: folder.appending(path: "absent"), now: { date })
        #expect(store.scripts.isEmpty)
        #expect(store.errorMessage != nil)
    }
}
