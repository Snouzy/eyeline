import SwiftUI

enum SetupHandle: Equatable {
    case bandEdge(Edge)
    case textEdge(HorizontalEdge)
    case readingLine
}

enum Layout {
    // MARK: - Geometry

    static func bandFrame(_ calibration: Calibration, in size: CGSize) -> CGRect {
        if calibration.position.hasVerticalBand {
            let x = span(center: calibration.bandCenter, thickness: calibration.bandThickness, length: size.width)
            return CGRect(x: x.start, y: 0, width: x.length, height: size.height)
        }
        let y = span(center: calibration.bandCenter, thickness: calibration.bandThickness, length: size.height)
        return CGRect(x: 0, y: y.start, width: size.width, height: y.length)
    }

    private static func span(center: Double, thickness: Double, length: Double) -> (start: Double, length: Double) {
        let thickness = min(max(thickness, Setting.minBandThickness), length / 2)
        return (min(max(center * length - thickness / 2, 0), length - thickness), thickness)
    }

    // Moves one edge of the band. The other edge stays.
    static func draggingBandEdge(
        _ edge: Edge, of band: CGRect, by distance: Double, in size: CGSize
    ) -> (center: Double, thickness: Double) {
        switch edge {
        case .leading: moving(low: band.minX, high: band.maxX, isLow: true, by: distance, length: size.width)
        case .trailing: moving(low: band.minX, high: band.maxX, isLow: false, by: distance, length: size.width)
        case .top: moving(low: band.minY, high: band.maxY, isLow: true, by: distance, length: size.height)
        case .bottom: moving(low: band.minY, high: band.maxY, isLow: false, by: distance, length: size.height)
        }
    }

    private static func moving(
        low: Double, high: Double, isLow: Bool, by distance: Double, length: Double
    ) -> (center: Double, thickness: Double) {
        let newLow = isLow ? min(max(low + distance, 0), high - Setting.minBandThickness) : low
        let newHigh = isLow ? high : max(min(high + distance, length), low + Setting.minBandThickness)
        return ((newLow + newHigh) / 2 / length, newHigh - newLow)
    }

    // The lines that the text widths are measured from.
    private static func textAnchors(
        band: CGRect, position: TextPosition, in size: CGSize
    ) -> (left: Double, right: Double) {
        position.hasVerticalBand ? (band.minX, band.maxX) : (size.width / 2, size.width / 2)
    }

    // Each side stops at its own screen edge. Text above or below a horizontal band stops at the band.
    static func textFrame(_ calibration: Calibration, band: CGRect, in size: CGSize) -> CGRect {
        let anchors = textAnchors(band: band, position: calibration.position, in: size)
        let left = min(calibration.leftWidth, anchors.left)
        let right = min(calibration.rightWidth, size.width - anchors.right)
        let (minX, maxX) = switch calibration.position {
        case .left: (anchors.left - left, anchors.left)
        case .right: (anchors.right, anchors.right + right)
        case .leftAndRight, .top, .bottom, .topAndBottom: (anchors.left - left, anchors.right + right)
        }
        let (minY, maxY) = switch calibration.position {
        case .left, .right, .leftAndRight, .topAndBottom: (0.0, size.height)
        case .top: (0.0, band.minY)
        case .bottom: (band.maxY, size.height)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    // The width of one side after a drag of its outer edge, from the text frame shown when the drag started.
    static func textWidth(
        dragging edge: HorizontalEdge, of text: CGRect, by distance: Double, band: CGRect, position: TextPosition,
        in size: CGSize
    ) -> Double {
        let anchors = textAnchors(band: band, position: position, in: size)
        switch edge {
        case .leading: return min(max(anchors.left - text.minX - distance, Setting.minTextWidth), anchors.left)
        case .trailing:
            return min(max(text.maxX - anchors.right + distance, Setting.minTextWidth), size.width - anchors.right)
        }
    }

    // The band in text coordinates. Left-and-right text flows around it.
    static func hole(band: CGRect, text: CGRect, position: TextPosition) -> ClosedRange<Double>? {
        switch position {
        case .leftAndRight: (band.minX - text.minX)...(band.maxX - text.minX)
        case .left, .right, .top, .bottom, .topAndBottom: nil
        }
    }

    // Where each line starts. The middle of left-and-right text is behind the Pocket.
    static func countdownX(band: CGRect, text: CGRect, position: TextPosition) -> Double {
        switch position {
        case .leftAndRight: (text.minX + band.minX) / 2
        case .left, .right, .top, .bottom, .topAndBottom: text.midX
        }
    }

    // Half a line inside the text area, so that the band never cuts the line read. Text above and below the
    // band runs behind the Pocket: there, the line read goes to the nearest side of the band.
    static func readingLineY(
        _ fraction: Double, text: CGRect, band: CGRect, position: TextPosition, height: Double, lineHeight: Double
    ) -> Double {
        let half = lineHeight / 2
        let wanted = clampedReadingLine(fraction) * height
        let y = min(max(wanted, text.minY + half), max(text.maxY - half, text.minY + half))
        guard position == .topAndBottom, (band.minY - half...band.maxY + half).contains(y) else { return y }
        return y < band.midY ? band.minY - half : band.maxY + half
    }

    static func readingLine(atY y: Double, height: Double) -> Double {
        clampedReadingLine(y / height)
    }

    private static func clampedReadingLine(_ fraction: Double) -> Double {
        min(max(fraction, Setting.readingLineRange.lowerBound), Setting.readingLineRange.upperBound)
    }

    // The nearest handle within 30 pt of a touch. The reading line is first, so it wins a tie.
    static func handle(
        at point: CGPoint, band: CGRect, text: CGRect, readingY: Double, position: TextPosition
    ) -> SetupHandle? {
        var distances: [(SetupHandle, Double)] = [(.readingLine, abs(point.y - readingY))]
        if position.hasVerticalBand {
            distances.append((.bandEdge(.leading), abs(point.x - band.minX)))
            distances.append((.bandEdge(.trailing), abs(point.x - band.maxX)))
        } else {
            distances.append((.bandEdge(.top), abs(point.y - band.minY)))
            distances.append((.bandEdge(.bottom), abs(point.y - band.maxY)))
        }
        if (text.minY...text.maxY).contains(point.y) {
            if position != .right {
                distances.append((.textEdge(.leading), abs(point.x - text.minX)))
            }
            if position != .left {
                distances.append((.textEdge(.trailing), abs(point.x - text.maxX)))
            }
        }
        guard let nearest = distances.min(by: { $0.1 < $1.1 }), nearest.1 <= 30 else { return nil }
        return nearest.0
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

    // The two fade-mask stops, as fractions of the column height: the text above fades out, the text below stays.
    static func fadeStops(readingY: Double, lineHeight: Double, height: Double) -> [Double] {
        let top = readingY - 1.5 * lineHeight
        return [top - 2 * lineHeight, top].map { min(max($0 / height, 0), 1) }
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
