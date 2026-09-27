import CoreGraphics
import Foundation

enum BandEdge {
    case leading
    case trailing
}

enum Layout {
    // MARK: - Geometry

    static func bandFrame(center: Double, width: Double, in size: CGSize) -> CGRect {
        let width = min(max(width, Setting.minBandWidth), size.width / 2)
        let x = min(max(center * size.width - width / 2, 0), size.width - width)
        return CGRect(x: x, y: 0, width: width, height: size.height)
    }

    static func draggingEdge(
        _ edge: BandEdge, of band: CGRect, by distance: Double, in size: CGSize
    ) -> (center: Double, width: Double) {
        var minX = band.minX
        var maxX = band.maxX
        switch edge {
        case .leading:
            minX = min(max(minX + distance, 0), maxX - Setting.minBandWidth)
        case .trailing:
            maxX = max(min(maxX + distance, size.width), minX + Setting.minBandWidth)
        }
        return ((minX + maxX) / 2 / size.width, maxX - minX)
    }

    static func stripWidth(band: CGRect, side: ColumnSide, in size: CGSize) -> Double {
        switch side {
        case .left: band.minX
        case .right: size.width - band.maxX
        }
    }

    static func columnFrame(band: CGRect, side: ColumnSide, width: Double, in size: CGSize) -> CGRect {
        let width = min(width, stripWidth(band: band, side: side, in: size))
        let x = switch side {
        case .left: band.minX - width
        case .right: band.maxX
        }
        return CGRect(x: x, y: 0, width: width, height: size.height)
    }

    static func readingLineY(_ fraction: Double, height: Double) -> Double {
        clampedReadingLine(fraction) * height
    }

    static func readingLine(atY y: Double, height: Double) -> Double {
        clampedReadingLine(y / height)
    }

    private static func clampedReadingLine(_ fraction: Double) -> Double {
        min(max(fraction, Setting.readingLineRange.lowerBound), Setting.readingLineRange.upperBound)
    }

    // MARK: - Scrolling

    static func lineHeight(fontSize: Double) -> Double {
        fontSize * 1.4
    }

    // The contentOffset.y values that put the first line, then the last line, on the reading line.
    static func offsetRange(textHeight: Double, lineHeight: Double, readingY: Double) -> ClosedRange<Double> {
        let start = lineHeight / 2 - readingY
        return start...(start + max(textHeight - lineHeight, 0))
    }

    static func pointsPerSecond(wordsPerMinute: Int, textHeight: Double, wordCount: Int) -> Double {
        guard wordCount > 0 else { return 0 }
        return Double(wordsPerMinute) / 60 * textHeight / Double(wordCount)
    }

    // Locations of the four fade-mask stops, as fractions of the column height.
    static func fadeStops(readingY: Double, lineHeight: Double, height: Double) -> [Double] {
        let top = readingY - 1.5 * lineHeight
        let bottom = readingY + 3.5 * lineHeight
        return [top - 2 * lineHeight, top, bottom, bottom + 2 * lineHeight].map { min(max($0 / height, 0), 1) }
    }

    // MARK: - Text

    static func wordCount(_ text: String) -> Int {
        text.split(whereSeparator: \.isWhitespace).count
    }

    static func title(_ text: String) -> String? {
        text.split(whereSeparator: \.isNewline)
            .lazy
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty }
    }

    static func duration(wordCount: Int, wordsPerMinute: Int) -> Int {
        guard wordsPerMinute > 0 else { return 0 }
        let seconds = Double(wordCount) * 60 / Double(wordsPerMinute)
        return Int((seconds / 10).rounded()) * 10
    }

    static func summary(wordCount: Int, wordsPerMinute: Int) -> String {
        let words = wordCount > 1 ? "\(wordCount) mots" : "\(wordCount) mot"
        let seconds = duration(wordCount: wordCount, wordsPerMinute: wordsPerMinute)
        let minutes = seconds / 60
        let rest = seconds % 60
        let time = switch (minutes, rest) {
        case (0, _): "\(rest) s"
        case (_, 0): "\(minutes) min"
        default: "\(minutes) min \(rest) s"
        }
        return "\(words) · ≈ \(time)"
    }
}
