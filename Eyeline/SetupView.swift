import SwiftUI

// Drawn over the full screen. The Pocket hides the middle of its band, so the user drags the visible edges.
struct SetupHandles: View {
    let size: CGSize
    let band: CGRect
    let text: CGRect
    let readingY: Double
    @Binding var calibration: Calibration

    @State private var drag: Drag?

    // The drag applies to the geometry shown when it started, not to the one that it changes.
    private struct Drag {
        let handle: SetupHandle
        let band: CGRect
        let text: CGRect
        let readingY: Double
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.orange.opacity(0.35))
                .frame(width: band.width, height: band.height)
                .position(x: band.midX, y: band.midY)
            bandEdges
                .stroke(.orange, lineWidth: 3)
            textEdges
                .stroke(.white, lineWidth: 3)
            Rectangle()
                .fill(.yellow)
                .frame(width: size.width, height: 3)
                .position(x: size.width / 2, y: readingY)
        }
        .frame(width: size.width, height: size.height)
        // Takes all the taps, so they do not start the prompter.
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged(dragChanged)
                .onEnded { _ in
                    drag = nil
                }
        )
    }

    private var bandEdges: Path {
        Path { path in
            if calibration.position.hasVerticalBand {
                for x in [band.minX, band.maxX] {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
            } else {
                for y in [band.minY, band.maxY] {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
            }
        }
    }

    private var textEdges: Path {
        Path { path in
            let edges = [
                calibration.position == .right ? nil : text.minX,
                calibration.position == .left ? nil : text.maxX,
            ]
            for x in edges.compactMap(\.self) {
                path.move(to: CGPoint(x: x, y: text.minY))
                path.addLine(to: CGPoint(x: x, y: text.maxY))
            }
        }
    }

    private func dragChanged(_ value: DragGesture.Value) {
        if drag == nil {
            let handle = Layout.handle(
                at: value.startLocation, band: band, text: text, readingY: readingY, position: calibration.position)
            guard let handle else { return }
            drag = Drag(handle: handle, band: band, text: text, readingY: readingY)
        }
        guard let drag else { return }
        let move = value.translation
        switch drag.handle {
        case .bandEdge(let edge):
            let distance = edge == .top || edge == .bottom ? move.height : move.width
            let moved = Layout.draggingBandEdge(edge, of: drag.band, by: distance, in: size)
            calibration.bandCenter = moved.center
            calibration.bandThickness = moved.thickness
        case .textEdge(let edge):
            let width = Layout.textWidth(
                dragging: edge, of: drag.text, by: move.width, band: drag.band, position: calibration.position,
                in: size)
            switch edge {
            case .leading: calibration.leftWidth = width
            case .trailing: calibration.rightWidth = width
            }
        case .readingLine:
            calibration.readingLine = Layout.readingLine(atY: drag.readingY + move.height, height: size.height)
        }
    }
}

// At the top: the handles run the full screen height, so they stay free below.
struct SetupPanel: View {
    @Binding var position: TextPosition
    @Binding var fontSize: Double
    @Binding var lineSpacing: Double
    let onDone: () -> Void

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        // Side by side in landscape, one under the other in the narrow portrait screen.
        let layout = verticalSizeClass == .regular
            ? AnyLayout(VStackLayout(alignment: .leading))
            : AnyLayout(HStackLayout(alignment: .top))
        layout {
            VStack(alignment: .leading) {
                Picker("Position du texte", selection: $position) {
                    ForEach(TextPosition.allCases, id: \.self) { position in
                        Text(Self.label(of: position)).tag(position)
                    }
                }
                .pickerStyle(.menu)
                Button("OK", action: onDone)
                    .buttonStyle(.borderedProminent)
            }
            .padding(10)
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Text("Taille du texte")
                Slider(value: $fontSize, in: Setting.fontSizeRange)
                Text("Interligne")
                Slider(value: $lineSpacing, in: Setting.lineSpacingRange)
            }
            .font(.caption)
            .frame(width: 200)
            .padding(10)
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
        }
        .environment(\.colorScheme, .dark)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
    }

    private static func label(of position: TextPosition) -> String {
        switch position {
        case .left: "À gauche"
        case .right: "À droite"
        case .leftAndRight: "À gauche et à droite"
        case .top: "En haut"
        case .bottom: "En bas"
        case .topAndBottom: "En haut et en bas"
        }
    }
}
