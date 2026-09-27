import SwiftUI

enum Layout {
    // MARK: - Geometry

    static func bandFrame(center: Double, width: Double, in size: CGSize) -> CGRect {
        let width = min(max(width, Setting.minBandWidth), size.width / 2)
        let x = min(max(center * size.width - width / 2, 0), size.width - width)
        return CGRect(x: x, y: 0, width: width, height: size.height)
    }

    static func draggingEdge(
        _ edge: HorizontalEdge, of band: CGRect, by distance: Double, in size: CGSize
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

    // A two-sided column spans both strips and the band. Each side stops at its own screen edge.
    static func columnFrame(
        band: CGRect, side: ColumnSide, leftWidth: Double, rightWidth: Double, in size: CGSize
    ) -> CGRect {
        let left = min(leftWidth, band.minX)
        let right = min(rightWidth, size.width - band.maxX)
        let (minX, maxX) = switch side {
        case .left: (band.minX - left, band.minX)
        case .both: (band.minX - left, band.maxX + right)
        case .right: (band.maxX, band.maxX + right)
        }
        return CGRect(x: minX, y: 0, width: maxX - minX, height: size.height)
    }

    // The outer edge of the left column is the leading edge, the one of the right column the trailing edge.
    static func columnWidth(
        dragging edge: HorizontalEdge, from width: Double, by distance: Double, band: CGRect, in size: CGSize
    ) -> Double {
        switch edge {
        case .leading: min(max(width - distance, Setting.minColumnWidth), band.minX)
        case .trailing: min(max(width + distance, Setting.minColumnWidth), size.width - band.maxX)
        }
    }

    // The band in column coordinates. The text of a two-sided column flows around it.
    static func hole(band: CGRect, column: CGRect, side: ColumnSide) -> ClosedRange<Double>? {
        switch side {
        case .left, .right: nil
        case .both: (band.minX - column.minX)...(band.maxX - column.minX)
        }
    }

    // Where each line starts. The middle of a two-sided column is behind the Pocket.
    static func countdownX(band: CGRect, column: CGRect, side: ColumnSide) -> Double {
        switch side {
        case .left, .right: column.midX
        case .both: (column.minX + band.minX) / 2
        }
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

    static func lineHeight(fontSize: Double, spacing: Double) -> Double {
        fontSize * spacing
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

    // A lone ">" or "-" is not a word: it would make the scroll faster than the voice.
    static func wordCount(_ text: String) -> Int {
        text.split(whereSeparator: \.isWhitespace).count { $0.contains { $0.isLetter || $0.isNumber } }
    }

    // Pasted scripts often keep their Markdown: quotes, headings, list marks, bold.
    static func plainText(_ text: String) -> String {
        text.replacing(/^[ \t]*(?:>[ \t]?)+/.anchorsMatchLineEndings(), with: "")
            .replacing(/^[ \t]*(?:#{1,6}|[-*+])[ \t]+/.anchorsMatchLineEndings(), with: "")
            .replacing(/\*\*|__/, with: "")
    }

    static func title(_ text: String) -> String? {
        plainText(text).split(whereSeparator: \.isNewline)
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
