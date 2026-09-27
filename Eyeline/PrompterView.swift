import SwiftUI

struct PrompterView: View {
    let text: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(Setting.wordsPerMinuteKey) private var wordsPerMinute = Setting.wordsPerMinute
    @AppStorage(Setting.fontSizeKey) private var fontSize = Setting.fontSize
    @AppStorage(Setting.columnWidthKey) private var columnWidth = Setting.columnWidth
    @AppStorage(Setting.columnSideKey) private var columnSide = Setting.columnSide
    @AppStorage(Setting.bandCenterKey) private var bandCenter = Setting.bandCenter
    @AppStorage(Setting.bandWidthKey) private var bandWidth = Setting.bandWidth
    @AppStorage(Setting.readingLineKey) private var readingLine = Setting.readingLine

    @State private var phase = Phase.ready
    @State private var phaseBeforeCountdown = Phase.ready
    @State private var count = 3
    @State private var countdown: Task<Void, Never>?
    @State private var resetToken = 0
    @State private var isSetupShown = false
    @State private var screen = CGSize.zero

    private enum Phase {
        case ready
        case countdown
        case scrolling
        case paused
        case ended
    }

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let size = proxy.size
                let band = Layout.bandFrame(center: bandCenter, width: bandWidth, in: size)
                let column = Layout.columnFrame(band: band, side: columnSide, width: columnWidth, in: size)
                let readingY = Layout.readingLineY(readingLine, height: size.height)
                ScrollingText(
                    text: text, fontSize: fontSize, columnFrame: column, readingY: readingY,
                    wordsPerMinute: wordsPerMinute, isScrolling: phase == .scrolling, resetToken: resetToken,
                    onTap: tap, onEnd: { phase = .ended })
                Capsule()
                    .fill(.gray)
                    .frame(width: 4, height: fontSize)
                    .position(x: columnSide == .right ? column.maxX + 8 : column.minX - 8, y: readingY)
                if phase == .countdown {
                    Text("\(count)")
                        .font(.system(size: fontSize * 2, weight: .bold))
                        .foregroundStyle(.white)
                        .position(x: column.midX, y: readingY)
                }
                if isSetupShown {
                    SetupHandles(
                        size: size, band: band, readingY: readingY,
                        bandCenter: $bandCenter, bandWidth: $bandWidth, readingLine: $readingLine)
                }
            }
            .ignoresSafeArea()
            .onGeometryChange(for: CGSize.self) { $0.size } action: { screen = $0 }

            if isSetupShown {
                SetupPanel(
                    columnSide: $columnSide, columnWidth: $columnWidth, fontSize: $fontSize,
                    maxColumnWidth: maxColumnWidth) {
                        isSetupShown = false
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: columnSide == .right ? .leading : .trailing)
                    .padding()
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

    private var maxColumnWidth: Double {
        let band = Layout.bandFrame(center: bandCenter, width: bandWidth, in: screen)
        return Layout.stripWidth(band: band, side: columnSide, in: screen)
    }

    // In the strip on the other side of the Pocket, so that the controls never cover the text.
    private var controls: some View {
        VStack(alignment: columnSide == .right ? .leading : .trailing, spacing: 12) {
            HStack {
                Button("Fermer", systemImage: "xmark") {
                    dismiss()
                }
                Button("Réglages", systemImage: "slider.horizontal.3") {
                    isSetupShown = true
                }
            }
            Spacer()
            Button("Revenir au début", systemImage: "backward.end.fill") {
                resetToken += 1
                phase = .ready
            }
            HStack {
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
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
        .tint(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: columnSide == .right ? .leading : .trailing)
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
