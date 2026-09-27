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
        let column = Layout.columnFrame(band: centredBand, side: .right, leftWidth: 90, rightWidth: 150, in: screen)
        #expect(column == CGRect(x: 577, y: 0, width: 150, height: 402))
    }

    @Test func leftColumnTouchesTheBand() {
        let column = Layout.columnFrame(band: centredBand, side: .left, leftWidth: 150, rightWidth: 90, in: screen)
        #expect(column == CGRect(x: 147, y: 0, width: 150, height: 402))
    }

    @Test func columnTakesTheFullStripWhenTheStripIsNarrower() {
        let right = Layout.columnFrame(band: centredBand, side: .right, leftWidth: 400, rightWidth: 400, in: screen)
        let left = Layout.columnFrame(band: centredBand, side: .left, leftWidth: 400, rightWidth: 400, in: screen)
        #expect(right.width == 297)
        #expect(left.minX == 0)
    }

    @Test func twoSidedColumnSpansBothStripsAndTheBand() {
        let column = Layout.columnFrame(band: centredBand, side: .both, leftWidth: 150, rightWidth: 150, in: screen)
        #expect(column == CGRect(x: 147, y: 0, width: 580, height: 402))
    }

    @Test func eachSideHasItsOwnWidth() {
        let column = Layout.columnFrame(band: centredBand, side: .both, leftWidth: 100, rightWidth: 200, in: screen)
        #expect(column == CGRect(x: 197, y: 0, width: 580, height: 402))
    }

    @Test func eachSideOfATwoSidedColumnStopsAtItsOwnScreenEdge() {
        // Off-centre band: the left strip is 197 pt wide, the right strip 397 pt.
        let band = CGRect(x: 197, y: 0, width: 280, height: 402)
        let column = Layout.columnFrame(band: band, side: .both, leftWidth: 300, rightWidth: 300, in: screen)
        #expect(column == CGRect(x: 0, y: 0, width: 777, height: 402))
    }

    @Test func textFlowsAroundTheBandInATwoSidedColumn() {
        let column = CGRect(x: 147, y: 0, width: 580, height: 402)
        #expect(Layout.hole(band: centredBand, column: column, side: .both) == 150...430)
    }

    @Test func aOneSidedColumnHasNoHole() {
        let column = CGRect(x: 577, y: 0, width: 150, height: 402)
        #expect(Layout.hole(band: centredBand, column: column, side: .right) == nil)
        #expect(Layout.hole(band: centredBand, column: column, side: .left) == nil)
    }

    @Test func countdownShowsWhereEachLineStarts() {
        let twoSided = CGRect(x: 147, y: 0, width: 580, height: 402)
        #expect(Layout.countdownX(band: centredBand, column: twoSided, side: .both) == 222)
        let right = CGRect(x: 577, y: 0, width: 150, height: 402)
        #expect(Layout.countdownX(band: centredBand, column: right, side: .right) == 652)
    }

    @Test func draggingAColumnEdgeOutwardWidensTheColumn() {
        #expect(Layout.columnWidth(dragging: .leading, from: 150, by: -50, band: centredBand, in: screen) == 200)
        #expect(Layout.columnWidth(dragging: .trailing, from: 150, by: 50, band: centredBand, in: screen) == 200)
    }

    @Test func aColumnEdgeStopsAtTheMinimumAndAtTheScreenEdge() {
        #expect(Layout.columnWidth(dragging: .leading, from: 150, by: 500, band: centredBand, in: screen) == 60)
        #expect(Layout.columnWidth(dragging: .leading, from: 150, by: -500, band: centredBand, in: screen) == 297)
        #expect(Layout.columnWidth(dragging: .trailing, from: 150, by: 500, band: centredBand, in: screen) == 297)
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

    @Test func lineHeightFollowsTheSpacing() {
        #expect(Layout.lineHeight(fontSize: 30, spacing: 1.5) == 45)
    }

    @Test func onlyTheLinesAlreadyReadFadeOut() {
        // One line above the reading line stays visible. Below it, the text stays visible to the bottom.
        #expect(Layout.fadeStops(readingY: 200, lineHeight: 40, height: 400) == [0.15, 0.35])
    }

    @Test func fadeStopsStayBetweenZeroAndOne() {
        #expect(Layout.fadeStops(readingY: 50, lineHeight: 40, height: 400) == [0, 0])
    }
}

struct TextTests {
    @Test func wordsAreSeparatedByWhiteSpace() {
        #expect(Layout.wordCount("On lance\nla  vidéo avec l'objectif") == 6)
        #expect(Layout.wordCount(" \n ") == 0)
    }

    @Test func tokensWithoutALetterOrADigitAreNotWords() {
        #expect(Layout.wordCount("> Dis-moi - **Mise en image** : 5") == 5)
    }

    @Test func plainTextDropsTheMarkdownMarks() {
        let markdown = "# Intro\n> Le 5 octobre\n> - **Mise** en __image__\n* Ton sobre\n+ Fondus\nUn 5 * 3 reste."
        #expect(Layout.plainText(markdown) == "Intro\nLe 5 octobre\nMise en image\nTon sobre\nFondus\nUn 5 * 3 reste.")
    }

    @Test func titleIsTheFirstLineThatIsNotEmpty() {
        #expect(Layout.title("\n   \n  Mon intro  \nla suite") == "Mon intro")
        #expect(Layout.title(" \n\t\n") == nil)
        #expect(Layout.title("> **Mon intro**\nla suite") == "Mon intro")
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
