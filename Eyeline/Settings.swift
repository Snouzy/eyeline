import Foundation

enum ColumnSide: String {
    case left
    case both
    case right
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

    static let leftColumnWidthKey = "leftColumnWidth"
    static let rightColumnWidthKey = "rightColumnWidth"
    static let columnWidth = 220.0
    static let minColumnWidth = 60.0

    static let columnSideKey = "columnSide"
    static let columnSide = ColumnSide.both

    static let bandCenterKey = "bandCenter"
    static let bandCenter = 0.5

    static let bandWidthKey = "bandWidth"
    static let bandWidth = 280.0
    static let minBandWidth = 20.0

    static let readingLineKey = "readingLine"
    static let readingLine = 0.5
    static let readingLineRange = 0.1...0.9
}
