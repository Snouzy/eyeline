import Foundation
import Testing
@testable import Eyeline

struct CalibrationStoreTests {
    private let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "CalibrationStoreTests.\(UUID().uuidString)"))
    }

    @Test func eachOrientationStartsWithItsDefault() {
        let store = CalibrationStore(defaults: defaults)
        #expect(store.landscape == .landscape)
        #expect(store.portrait == .portrait)
    }

    @Test func aChangeIsSavedForItsOrientationOnly() {
        CalibrationStore(defaults: defaults).portrait.readingLine = 0.2
        let reloaded = CalibrationStore(defaults: defaults)
        #expect(reloaded.portrait.readingLine == 0.2)
        #expect(reloaded.landscape == .landscape)
    }

    @Test func unreadableDataFallsBackToTheDefault() {
        defaults.set(Data([1, 2, 3]), forKey: "landscapeCalibration")
        #expect(CalibrationStore(defaults: defaults).landscape == .landscape)
    }
}
