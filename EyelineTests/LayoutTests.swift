import CoreGraphics
import Testing
@testable import Eyeline

// An iPhone 16 Pro in landscape, then in portrait.
private let screen = CGSize(width: 874, height: 402)
private let portraitScreen = CGSize(width: 402, height: 874)
private let centredBand = CGRect(x: 297, y: 0, width: 280, height: 402)
private let portraitBand = CGRect(x: 0, y: 337, width: 402, height: 200)

struct BandTests {
    @Test func defaultLandscapeBandIsVerticalAndCentred() {
        #expect(Layout.bandFrame(.landscape, in: screen) == centredBand)
    }

    @Test func topAndBottomPositionsGetAHorizontalBand() {
        let calibration = Calibration(position: .top, bandCenter: 0.5, bandThickness: 200)
        #expect(Layout.bandFrame(calibration, in: portraitScreen) == portraitBand)
    }

    @Test func bandStaysOnScreen() {
        #expect(Layout.bandFrame(Calibration(bandCenter: 0.99), in: screen).minX == 594)
        #expect(Layout.bandFrame(Calibration(bandCenter: 0.01), in: screen).minX == 0)
    }

    @Test func bandThicknessIsClampedToHalfTheScreen() {
        #expect(Layout.bandFrame(Calibration(bandThickness: 5), in: screen).width == 20)
        #expect(Layout.bandFrame(Calibration(bandThickness: 1000), in: screen).width == 437)
        #expect(Layout.bandFrame(Calibration(position: .top, bandThickness: 1000), in: screen).height == 201)
    }

    @Test func draggingOneEdgeKeepsTheOtherEdge() {
        let leading = Layout.draggingBandEdge(.leading, of: centredBand, by: -40, in: screen)
        #expect(leading.thickness == 320)
        #expect(leading.center * screen.width == 417)
        let trailing = Layout.draggingBandEdge(.trailing, of: centredBand, by: 30, in: screen)
        #expect(trailing.thickness == 310)
        #expect(trailing.center * screen.width == 452)
    }

    @Test func draggingTheTopEdgeOfAHorizontalBand() {
        let moved = Layout.draggingBandEdge(.top, of: portraitBand, by: -37, in: portraitScreen)
        #expect(moved.thickness == 237)
        #expect(moved.center * portraitScreen.height == 418.5)
    }

    @Test func anEdgeCannotCrossTheOtherOne() {
        #expect(Layout.draggingBandEdge(.leading, of: centredBand, by: 500, in: screen).thickness == 20)
        #expect(Layout.draggingBandEdge(.trailing, of: centredBand, by: -500, in: screen).thickness == 20)
    }

    @Test func anEdgeStopsAtTheScreenEdge() {
        #expect(Layout.draggingBandEdge(.leading, of: centredBand, by: -1000, in: screen).thickness == 577)
        #expect(Layout.draggingBandEdge(.bottom, of: portraitBand, by: 1000, in: portraitScreen).thickness == 537)
    }
}

struct TextFrameTests {
    @Test func rightTextTouchesTheBand() {
        let calibration = Calibration(position: .right, leftWidth: 90, rightWidth: 150)
        let text = Layout.textFrame(calibration, band: centredBand, in: screen)
        #expect(text == CGRect(x: 577, y: 0, width: 150, height: 402))
    }

    @Test func leftTextTouchesTheBand() {
        let calibration = Calibration(position: .left, leftWidth: 150, rightWidth: 90)
        let text = Layout.textFrame(calibration, band: centredBand, in: screen)
        #expect(text == CGRect(x: 147, y: 0, width: 150, height: 402))
    }

    @Test func textTakesTheFullStripWhenTheStripIsNarrower() {
        let right = Layout.textFrame(Calibration(position: .right, rightWidth: 400), band: centredBand, in: screen)
        let left = Layout.textFrame(Calibration(position: .left, leftWidth: 400), band: centredBand, in: screen)
        #expect(right.width == 297)
        #expect(left.minX == 0)
    }

    @Test func leftAndRightTextSpansBothStripsAndTheBand() {
        let calibration = Calibration(position: .leftAndRight, leftWidth: 100, rightWidth: 200)
        let text = Layout.textFrame(calibration, band: centredBand, in: screen)
        #expect(text == CGRect(x: 197, y: 0, width: 580, height: 402))
    }

    @Test func eachSideStopsAtItsOwnScreenEdge() {
        // Off-centre band: the left strip is 197 pt wide, the right strip 397 pt.
        let band = CGRect(x: 197, y: 0, width: 280, height: 402)
        let calibration = Calibration(position: .leftAndRight, leftWidth: 300, rightWidth: 300)
        #expect(Layout.textFrame(calibration, band: band, in: screen) == CGRect(x: 0, y: 0, width: 777, height: 402))
    }

    @Test(arguments: [
        (TextPosition.top, CGRect(x: 51, y: 0, width: 250, height: 337)),
        (TextPosition.bottom, CGRect(x: 51, y: 537, width: 250, height: 337)),
        (TextPosition.topAndBottom, CGRect(x: 51, y: 0, width: 250, height: 874)),
    ])
    func withAHorizontalBandTheWidthsCountFromTheScreenCentre(position: TextPosition, expected: CGRect) {
        let calibration = Calibration(position: position, leftWidth: 150, rightWidth: 100)
        #expect(Layout.textFrame(calibration, band: portraitBand, in: portraitScreen) == expected)
    }

    @Test func draggingATextEdgeOutwardWidensTheText() {
        let text = CGRect(x: 147, y: 0, width: 580, height: 402)
        let leading = Layout.textWidth(
            dragging: .leading, of: text, by: -50, band: centredBand, position: .leftAndRight, in: screen)
        let trailing = Layout.textWidth(
            dragging: .trailing, of: text, by: 50, band: centredBand, position: .leftAndRight, in: screen)
        #expect(leading == 200)
        #expect(trailing == 200)
    }

    @Test func aTextEdgeStopsAtTheMinimumAndAtTheScreenEdge() {
        let text = CGRect(x: 147, y: 0, width: 580, height: 402)
        let narrowest = Layout.textWidth(
            dragging: .leading, of: text, by: 500, band: centredBand, position: .leftAndRight, in: screen)
        let widest = Layout.textWidth(
            dragging: .trailing, of: text, by: 500, band: centredBand, position: .leftAndRight, in: screen)
        let portraitWidest = Layout.textWidth(
            dragging: .trailing, of: CGRect(x: 51, y: 0, width: 250, height: 337), by: 500,
            band: portraitBand, position: .top, in: portraitScreen)
        #expect(narrowest == 60)
        #expect(widest == 297)
        #expect(portraitWidest == 201)
    }

    @Test func onlyLeftAndRightTextFlowsAroundTheBand() {
        let text = CGRect(x: 147, y: 0, width: 580, height: 402)
        #expect(Layout.hole(band: centredBand, text: text, position: .leftAndRight) == 150...430)
        #expect(Layout.hole(band: centredBand, text: text, position: .right) == nil)
        #expect(Layout.hole(band: portraitBand, text: text, position: .topAndBottom) == nil)
    }

    @Test func countdownShowsWhereEachLineStarts() {
        let twoSided = CGRect(x: 147, y: 0, width: 580, height: 402)
        #expect(Layout.countdownX(band: centredBand, text: twoSided, position: .leftAndRight) == 222)
        let right = CGRect(x: 577, y: 0, width: 150, height: 402)
        #expect(Layout.countdownX(band: centredBand, text: right, position: .right) == 652)
    }
}

struct ReadingLineTests {
    private let fullHeight = CGRect(x: 0, y: 0, width: 874, height: 400)

    @Test func readingLineIsClamped() {
        let middle = Layout.readingLineY(
            0.5, text: fullHeight, band: centredBand, position: .leftAndRight, height: 400, lineHeight: 40)
        let high = Layout.readingLineY(
            0.01, text: fullHeight, band: centredBand, position: .leftAndRight, height: 400, lineHeight: 40)
        #expect(middle == 200)
        #expect(high == 40)
        #expect(Layout.readingLine(atY: 390, height: 400) == 0.9)
    }

    // Text above and below the band runs behind the Pocket: the line read goes to the nearest side.
    @Test func theLineReadIsNeverBehindThePocket() {
        let full = CGRect(x: 0, y: 0, width: 402, height: 874)
        let nearTop = Layout.readingLineY(
            0.45, text: full, band: portraitBand, position: .topAndBottom, height: 874, lineHeight: 40)
        let nearBottom = Layout.readingLineY(
            0.55, text: full, band: portraitBand, position: .topAndBottom, height: 874, lineHeight: 40)
        #expect(nearTop == 317)
        #expect(nearBottom == 557)
    }

    // Half a line inside: the line read is never cut by the band.
    @Test func theLineReadStaysWholeInsideTheText() {
        let above = CGRect(x: 51, y: 0, width: 250, height: 337)
        let below = CGRect(x: 51, y: 537, width: 250, height: 337)
        let lowest = Layout.readingLineY(
            0.6, text: above, band: portraitBand, position: .top, height: 874, lineHeight: 40)
        let highest = Layout.readingLineY(
            0.3, text: below, band: portraitBand, position: .bottom, height: 874, lineHeight: 40)
        #expect(lowest == 317)
        #expect(highest == 557)
    }
}

struct SetupHandleTests {
    private let text = CGRect(x: 147, y: 0, width: 580, height: 402)

    private func handle(at point: CGPoint) -> SetupHandle? {
        Layout.handle(at: point, band: centredBand, text: text, readingY: 201, position: .leftAndRight)
    }

    @Test func aTouchTakesTheNearestHandle() {
        #expect(handle(at: CGPoint(x: 300, y: 50)) == .bandEdge(.leading))
        #expect(handle(at: CGPoint(x: 150, y: 100)) == .textEdge(.leading))
        #expect(handle(at: CGPoint(x: 500, y: 210)) == .readingLine)
        #expect(handle(at: CGPoint(x: 500, y: 100)) == nil)
    }

    @Test func theReadingLineWinsATie() {
        let top = CGRect(x: 51, y: 0, width: 250, height: 337)
        let handle = Layout.handle(
            at: CGPoint(x: 200, y: 340), band: portraitBand, text: top, readingY: 337, position: .top)
        #expect(handle == .readingLine)
    }

    @Test func textEdgesOnlyTakeTouchesBesideTheText() {
        let top = CGRect(x: 51, y: 0, width: 250, height: 337)
        let handle = Layout.handle(
            at: CGPoint(x: 52, y: 700), band: portraitBand, text: top, readingY: 200, position: .top)
        #expect(handle == nil)
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
