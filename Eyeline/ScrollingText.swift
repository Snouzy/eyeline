import SwiftUI
import UIKit

struct ScrollingText: UIViewRepresentable {
    let text: String
    let fontSize: Double
    let columnFrame: CGRect
    let readingY: Double
    let wordsPerMinute: Int
    let isScrolling: Bool
    let resetToken: Int
    let onTap: () -> Void
    let onEnd: () -> Void

    func makeUIView(context: Context) -> PrompterCanvas {
        PrompterCanvas()
    }

    func updateUIView(_ canvas: PrompterCanvas, context: Context) {
        canvas.onTap = onTap
        canvas.onEnd = onEnd
        canvas.update(
            text: text, fontSize: fontSize, columnFrame: columnFrame, readingY: readingY,
            wordsPerMinute: wordsPerMinute, isScrolling: isScrolling, resetToken: resetToken)
    }
}

final class PrompterCanvas: UIView {
    var onTap: () -> Void = {}
    var onEnd: () -> Void = {}

    private let column = UIView()
    // TextKit 1: TextKit 2 estimates the height of long texts, and the speed needs the real height.
    private let textView = UITextView(usingTextLayoutManager: false)
    private let fade = CAGradientLayer()
    private var displayLink: CADisplayLink?

    private var text = ""
    private var fontSize = 0.0
    private var readingY = 0.0
    private var resetToken = 0
    private var wordCount = 0
    private var textHeight = 0.0
    private var offsets = 0.0...0.0
    private var speed = 0.0
    private var startOffset = 0.0
    private var startTime = 0.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        textView.isEditable = false
        textView.isSelectable = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.contentInsetAdjustmentBehavior = .never
        textView.showsVerticalScrollIndicator = false
        fade.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        column.layer.mask = fade
        column.addSubview(textView)
        addSubview(column)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    func update(
        text: String, fontSize: Double, columnFrame: CGRect, readingY: Double,
        wordsPerMinute: Int, isScrolling: Bool, resetToken: Int
    ) {
        if text != self.text || fontSize != self.fontSize || columnFrame != column.frame || readingY != self.readingY {
            let progress = self.progress
            self.text = text
            self.fontSize = fontSize
            self.readingY = readingY
            column.frame = columnFrame
            textView.frame = column.bounds
            layoutText()
            textView.contentOffset.y = offsets.lowerBound + progress * (offsets.upperBound - offsets.lowerBound)
        }
        if resetToken != self.resetToken {
            self.resetToken = resetToken
            textView.contentOffset.y = offsets.lowerBound
        }
        textView.isUserInteractionEnabled = !isScrolling
        if isScrolling {
            start(wordsPerMinute: wordsPerMinute)
        } else {
            stop()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            stop()
        }
    }

    // 0 when the first line is on the reading line, 1 when the last line is on it.
    private var progress: Double {
        let span = offsets.upperBound - offsets.lowerBound
        guard span > 0 else { return 0 }
        return min(max((textView.contentOffset.y - offsets.lowerBound) / span, 0), 1)
    }

    private func layoutText() {
        let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        let lineHeight = Layout.lineHeight(fontSize: fontSize)
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        textView.attributedText = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraph,
            // A fixed line height puts the extra space above the glyphs. This centres them in the line.
            .baselineOffset: (lineHeight - font.lineHeight) / 2,
        ])
        textView.layoutManager.ensureLayout(for: textView.textContainer)
        textHeight = textView.layoutManager.usedRect(for: textView.textContainer).height
        wordCount = Layout.wordCount(text)
        offsets = Layout.offsetRange(textHeight: textHeight, lineHeight: lineHeight, readingY: readingY)
        textView.contentInset = UIEdgeInsets(
            top: -offsets.lowerBound, left: 0,
            bottom: max(offsets.upperBound + column.bounds.height - textHeight, 0), right: 0)
        // The mask is a standalone layer: without this, each change animates for 0.25 s.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fade.frame = column.bounds
        fade.locations = Layout.fadeStops(readingY: readingY, lineHeight: lineHeight, height: column.bounds.height)
            .map { NSNumber(value: $0) }
        CATransaction.commit()
    }

    private func start(wordsPerMinute: Int) {
        guard displayLink == nil else { return }
        speed = Layout.pointsPerSecond(wordsPerMinute: wordsPerMinute, textHeight: textHeight, wordCount: wordCount)
        startOffset = textView.contentOffset.y
        startTime = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick(_ link: CADisplayLink) {
        let y = startOffset + speed * (link.targetTimestamp - startTime)
        guard y < offsets.upperBound else {
            textView.contentOffset.y = offsets.upperBound
            stop()
            onEnd()
            return
        }
        textView.contentOffset.y = y
    }

    @objc private func tapped() {
        onTap()
    }
}
