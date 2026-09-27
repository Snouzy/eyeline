import CoreGraphics
import Testing
@testable import Eyeline

// An iPhone 16 Pro in landscape.
private let screen = CGSize(width: 874, height: 402)
private let centredBand = CGRect(x: 297, y: 0, width: 280, height: 402)

struct BandTests {
    @Test func defaultBandIsCentred() {
        #expect(Layout.bandFrame(center: 0.5, width: 280, in: screen) == centredBand)
    }

    @Test func bandStaysOnScreen() {
        #expect(Layout.bandFrame(center: 0.99, width: 280, in: screen).minX == 594)
        #expect(Layout.bandFrame(center: 0.01, width: 280, in: screen).minX == 0)
    }

    @Test func bandWidthIsClamped() {
        #expect(Layout.bandFrame(center: 0.5, width: 5, in: screen).width == 20)
        #expect(Layout.bandFrame(center: 0.5, width: 1000, in: screen).width == 437)
    }

    @Test func draggingTheLeadingEdgeKeepsTheTrailingEdge() {
        let moved = Layout.draggingEdge(.leading, of: centredBand, by: -40, in: screen)
        #expect(moved.width == 320)
        #expect(moved.center * screen.width == 417)
    }

    @Test func draggingTheTrailingEdgeKeepsTheLeadingEdge() {
        let moved = Layout.draggingEdge(.trailing, of: centredBand, by: 30, in: screen)
        #expect(moved.width == 310)
        #expect(moved.center * screen.width == 452)
    }

    @Test func anEdgeCannotCrossTheOtherOne() {
        #expect(Layout.draggingEdge(.leading, of: centredBand, by: 500, in: screen).width == 20)
        #expect(Layout.draggingEdge(.trailing, of: centredBand, by: -500, in: screen).width == 20)
    }

    @Test func anEdgeStopsAtTheScreenEdge() {
        #expect(Layout.draggingEdge(.leading, of: centredBand, by: -1000, in: screen).width == 577)
        #expect(Layout.draggingEdge(.trailing, of: centredBand, by: 1000, in: screen).width == 577)
    }
}

struct ColumnTests {
    @Test func rightColumnTouchesTheBand() {
        let column = Layout.columnFrame(band: centredBand, side: .right, width: 150, in: screen)
        #expect(column == CGRect(x: 577, y: 0, width: 150, height: 402))
    }

    @Test func leftColumnTouchesTheBand() {
        let column = Layout.columnFrame(band: centredBand, side: .left, width: 150, in: screen)
        #expect(column == CGRect(x: 147, y: 0, width: 150, height: 402))
    }

    @Test func columnTakesTheFullStripWhenTheStripIsNarrower() {
        #expect(Layout.columnFrame(band: centredBand, side: .right, width: 400, in: screen).width == 297)
        #expect(Layout.columnFrame(band: centredBand, side: .left, width: 400, in: screen).minX == 0)
    }

    @Test func readingLineIsClamped() {
        #expect(Layout.readingLineY(0.5, height: 402) == 201)
        #expect(Layout.readingLineY(0.01, height: 400) == 40)
        #expect(Layout.readingLine(atY: 390, height: 400) == 0.9)
    }
}

struct ScrollTests {
    @Test func speedFollowsWordsPerMinute() {
        // 120 words/min = 2 words/s; 1000 pt for 100 words = 10 pt per word.
        #expect(Layout.pointsPerSecond(wordsPerMinute: 120, textHeight: 1000, wordCount: 100) == 20)
    }

    @Test func speedIsZeroWithoutWords() {
        #expect(Layout.pointsPerSecond(wordsPerMinute: 120, textHeight: 1000, wordCount: 0) == 0)
    }

    @Test func offsetRangePutsTheFirstThenTheLastLineOnTheReadingLine() {
        let range = Layout.offsetRange(textHeight: 480, lineHeight: 48, readingY: 200)
        #expect(range == -176...256)
    }

    @Test func offsetRangeOfOneLineIsAPoint() {
        #expect(Layout.offsetRange(textHeight: 48, lineHeight: 48, readingY: 200) == -176...(-176))
    }

    @Test func fadeStopsStayBetweenZeroAndOne() {
        let stops = Layout.fadeStops(readingY: 200, lineHeight: 40, height: 400)
        #expect(stops == [0.15, 0.35, 0.85, 1])
    }
}

struct TextTests {
    @Test func wordsAreSeparatedByWhiteSpace() {
        #expect(Layout.wordCount("On lance\nla  vidéo avec l'objectif") == 6)
        #expect(Layout.wordCount(" \n ") == 0)
    }

    @Test func titleIsTheFirstLineThatIsNotEmpty() {
        #expect(Layout.title("\n   \n  Mon intro  \nla suite") == "Mon intro")
        #expect(Layout.title(" \n\t\n") == nil)
    }

    @Test func durationIsRoundedToTenSeconds() {
        // 212 words at 130 words/min = 97.8 s.
        #expect(Layout.duration(wordCount: 212, wordsPerMinute: 130) == 100)
    }

    @Test(arguments: [
        (1, "1 mot · ≈ 0 s"),
        (87, "87 mots · ≈ 40 s"),
        (390, "390 mots · ≈ 3 min"),
        (325, "325 mots · ≈ 2 min 30 s"),
    ])
    func summary(wordCount: Int, expected: String) {
        #expect(Layout.summary(wordCount: wordCount, wordsPerMinute: 130) == expected)
    }
}
