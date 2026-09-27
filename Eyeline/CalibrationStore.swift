import Foundation
import Observation

// The landscape and the portrait calibrations, saved as JSON in the user defaults.
@Observable
final class CalibrationStore {
    var landscape: Calibration {
        didSet { save(landscape, as: Self.landscapeKey) }
    }
    var portrait: Calibration {
        didSet { save(portrait, as: Self.portraitKey) }
    }

    private static let landscapeKey = "landscapeCalibration"
    private static let portraitKey = "portraitCalibration"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        landscape = Self.load(Self.landscapeKey, from: defaults) ?? .landscape
        portrait = Self.load(Self.portraitKey, from: defaults) ?? .portrait
    }

    private static func load(_ key: String, from defaults: UserDefaults) -> Calibration? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Calibration.self, from: data)
    }

    private func save(_ calibration: Calibration, as key: String) {
        defaults.set(try? JSONEncoder().encode(calibration), forKey: key)
    }
}
