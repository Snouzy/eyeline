import Foundation
import Observation

struct Script: Identifiable {
    // The file name. It never changes after creation.
    let id: String
    var text: String
    var modified: Date
}

@Observable
final class ScriptStore {
    private(set) var scripts: [Script] = []
    var errorMessage: String?

    private let folder: URL
    private let now: () -> Date

    private static let fileNameFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return formatter
    }()

    init(folder: URL = URL.documentsDirectory, now: @escaping () -> Date = Date.init) {
        self.folder = folder
        self.now = now
        reload()
    }

    private func reload() {
        let urls: [URL]
        do {
            urls = try FileManager.default.contentsOfDirectory(
                at: folder, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)
        } catch {
            errorMessage = error.localizedDescription
            scripts = []
            return
        }
        scripts = urls
            .filter { $0.pathExtension == "txt" }
            .compactMap { url in
                guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
                let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
                return Script(id: url.lastPathComponent, text: text, modified: values?.contentModificationDate ?? .distantPast)
            }
            .sorted { $0.modified > $1.modified }
        // The editor deletes an empty script when it closes. If the app was killed first, the file is still here.
        for script in scripts where Layout.wordCount(script.text) == 0 {
            delete(id: script.id)
        }
    }

    func create(text: String = "") -> Script? {
        let date = now()
        let base = Self.fileNameFormat.string(from: date)
        var name = "\(base).txt"
        var copy = 2
        while FileManager.default.fileExists(atPath: url(of: name).path) {
            name = "\(base) \(copy).txt"
            copy += 1
        }
        let script = Script(id: name, text: text, modified: date)
        guard write(script) else { return nil }
        scripts.insert(script, at: 0)
        return script
    }

    func save(id: String, text: String) {
        guard let index = scripts.firstIndex(where: { $0.id == id }), scripts[index].text != text else { return }
        var script = scripts.remove(at: index)
        script.text = text
        script.modified = now()
        scripts.insert(script, at: 0)
        write(script)
    }

    func delete(id: String) {
        do {
            try FileManager.default.removeItem(at: url(of: id))
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        scripts.removeAll { $0.id == id }
    }

    private func url(of name: String) -> URL {
        folder.appending(path: name)
    }

    @discardableResult
    private func write(_ script: Script) -> Bool {
        do {
            try script.text.write(to: url(of: script.id), atomically: true, encoding: .utf8)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
