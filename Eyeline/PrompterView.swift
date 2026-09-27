import SwiftUI

struct PrompterView: View {
    let text: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @AppStorage(Setting.wordsPerMinuteKey) private var wordsPerMinute = Setting.wordsPerMinute
    @AppStorage(Setting.fontSizeKey) private var fontSize = Setting.fontSize
    @AppStorage(Setting.lineSpacingKey) private var lineSpacing = Setting.lineSpacing
    @State private var calibrations = CalibrationStore()
    @State private var phase = Phase.ready
    @State private var phaseBeforeCountdown = Phase.ready
    @State private var count = 3
    @State private var countdown: Task<Void, Never>?
    @State private var resetToken = 0
    @State private var isSetupShown = false

    private enum Phase {
        case ready
        case countdown
        case scrolling
        case paused
        case ended
    }

    // On iPhone, the vertical size class is regular in portrait only.
    private var calibration: Binding<Calibration> {
        verticalSizeClass == .regular ? $calibrations.portrait : $calibrations.landscape
    }

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let size = proxy.size
                let current = calibration.wrappedValue
                let band = Layout.bandFrame(current, in: size)
                let textFrame = Layout.textFrame(current, band: band, in: size)
                let readingY = Layout.readingLineY(
                    current.readingLine, text: textFrame, band: band, position: current.position,
                    height: size.height, lineHeight: Layout.lineHeight(fontSize: fontSize, spacing: lineSpacing))
                ScrollingText(
                    text: text, fontSize: fontSize, lineSpacing: lineSpacing, columnFrame: textFrame,
                    hole: Layout.hole(band: band, text: textFrame, position: current.position),
                    readingY: readingY - textFrame.minY, wordsPerMinute: wordsPerMinute,
                    isScrolling: phase == .scrolling, resetToken: resetToken, onTap: tap, onEnd: { phase = .ended })
                Capsule()
                    .fill(.gray)
                    .frame(width: 4, height: fontSize)
                    .position(x: current.position == .left ? textFrame.minX - 8 : textFrame.maxX + 8, y: readingY)
                if phase == .countdown {
                    Text("\(count)")
                        .font(.system(size: fontSize * 2, weight: .bold))
                        .foregroundStyle(.white)
                        .position(
                            x: Layout.countdownX(band: band, text: textFrame, position: current.position), y: readingY)
                }
                if isSetupShown {
                    SetupHandles(size: size, band: band, text: textFrame, readingY: readingY, calibration: calibration)
                }
            }
            .ignoresSafeArea()

            if isSetupShown {
                SetupPanel(position: calibration.position, fontSize: $fontSize, lineSpacing: $lineSpacing) {
                    isSetupShown = false
                }
            } else if phase != .scrolling && phase != .countdown {
                controls
            }
        }
        .background(.black)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            countdown?.cancel()
        }
        .onChange(of: scenePhase) {
            if scenePhase != .active {
                pause()
            }
        }
    }

    // At the top: the fade hides the text there, so the controls never cover what the user reads.
    private var controls: some View {
        HStack {
            Button("Fermer", systemImage: "xmark") {
                dismiss()
            }
            Button("Réglages", systemImage: "slider.horizontal.3") {
                isSetupShown = true
            }
            Button("Revenir au début", systemImage: "backward.end.fill") {
                resetToken += 1
                phase = .ready
            }
            Spacer()
            Button("Moins vite", systemImage: "minus") {
                changeSpeed(by: -Setting.wordsPerMinuteStep)
            }
            Text("\(wordsPerMinute) mots/min")
                .monospacedDigit()
                .foregroundStyle(.white)
            Button("Plus vite", systemImage: "plus") {
                changeSpeed(by: Setting.wordsPerMinuteStep)
            }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
        .tint(.white)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
    }

    private func changeSpeed(by step: Int) {
        let range = Setting.wordsPerMinuteRange
        wordsPerMinute = min(max(wordsPerMinute + step, range.lowerBound), range.upperBound)
    }

    private func tap() {
        switch phase {
        case .ready, .paused:
            startCountdown()
        case .ended:
            resetToken += 1
            phase = .ready
            startCountdown()
        case .countdown, .scrolling:
            pause()
        }
    }

    private func pause() {
        switch phase {
        case .countdown:
            countdown?.cancel()
            phase = phaseBeforeCountdown
        case .scrolling:
            phase = .paused
        case .ready, .paused, .ended:
            break
        }
    }

    // The phone stands behind the Pocket: the user needs time to go back to the filming position.
    private func startCountdown() {
        phaseBeforeCountdown = phase
        phase = .countdown
        countdown = Task {
            for second in [3, 2, 1] {
                count = second
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
            }
            phase = .scrolling
        }
    }
}
