import Foundation

enum TextPosition: String, CaseIterable, Codable {
    case left
    case right
    case leftAndRight
    case top
    case bottom
    case topAndBottom

    // Text on the left or on the right goes with a vertical band, text above or below with a horizontal band.
    var hasVerticalBand: Bool {
        switch self {
        case .left, .right, .leftAndRight: true
        case .top, .bottom, .topAndBottom: false
        }
    }
}

// Where the Pocket and the text are on the screen. Landscape and portrait each keep their own.
struct Calibration: Codable, Equatable {
    var position = TextPosition.leftAndRight
    // A fraction of the screen width for a vertical band, of the screen height for a horizontal band.
    var bandCenter = 0.5
    var bandThickness = 280.0
    // Measured from the band edges with a vertical band, from the screen centre with a horizontal band.
    var leftWidth = 220.0
    var rightWidth = 220.0
    var readingLine = 0.5

    static let landscape = Calibration()
    static let portrait = Calibration(
        position: .top, bandCenter: 0.6, bandThickness: 200, leftWidth: 150, rightWidth: 150, readingLine: 0.35)
}

// @AppStorage needs the key and the default value at each use site. Both come from here.
enum Setting {
    static let wordsPerMinuteKey = "wordsPerMinute"
    static let wordsPerMinute = 130
    static let wordsPerMinuteRange = 60...240
    static let wordsPerMinuteStep = 10

    static let fontSizeKey = "fontSize"
    static let fontSize = 34.0
    static let fontSizeRange = 12.0...80.0

    static let lineSpacingKey = "lineSpacing"
    static let lineSpacing = 1.4
    static let lineSpacingRange = 1.0...2.0

    static let minTextWidth = 60.0
    static let minBandThickness = 20.0
    static let readingLineRange = 0.1...0.9
}
