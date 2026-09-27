import SwiftUI

// Drawn over the full screen. The Pocket hides the middle of the band, so the user drags its visible edges.
struct SetupHandles: View {
    let size: CGSize
    let band: CGRect
    let readingY: Double
    @Binding var bandCenter: Double
    @Binding var bandWidth: Double
    @Binding var readingLine: Double

    @State private var bandAtDragStart: CGRect?
    @State private var lineAtDragStart: Double?

    var body: some View {
        ZStack {
            // Takes the taps, so they do not start the prompter.
            Color.clear
                .contentShape(Rectangle())
            Rectangle()
                .fill(.orange.opacity(0.35))
                .frame(width: band.width, height: size.height)
                .position(x: band.midX, y: size.height / 2)
            edge(.leading, at: band.minX)
            edge(.trailing, at: band.maxX)
            line
        }
    }

    private func edge(_ edge: BandEdge, at x: Double) -> some View {
        Rectangle()
            .fill(.orange)
            .frame(width: 3)
            .frame(width: 44, height: size.height)
            .contentShape(Rectangle())
            .position(x: x, y: size.height / 2)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let start = bandAtDragStart ?? band
                        bandAtDragStart = start
                        let moved = Layout.draggingEdge(edge, of: start, by: value.translation.width, in: size)
                        bandCenter = moved.center
                        bandWidth = moved.width
                    }
                    .onEnded { _ in
                        bandAtDragStart = nil
                    }
            )
    }

    private var line: some View {
        Rectangle()
            .fill(.orange)
            .frame(height: 3)
            .frame(width: size.width, height: 44)
            .contentShape(Rectangle())
            .position(x: size.width / 2, y: readingY)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let start = lineAtDragStart ?? readingY
                        lineAtDragStart = start
                        readingLine = Layout.readingLine(atY: start + value.translation.height, height: size.height)
                    }
                    .onEnded { _ in
                        lineAtDragStart = nil
                    }
            )
    }
}

struct SetupPanel: View {
    @Binding var columnSide: ColumnSide
    @Binding var columnWidth: Double
    @Binding var fontSize: Double
    let maxColumnWidth: Double
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Côté du texte", selection: $columnSide) {
                Text("Gauche").tag(ColumnSide.left)
                Text("Droite").tag(ColumnSide.right)
            }
            .pickerStyle(.segmented)
            Text("Largeur de la colonne")
            Slider(value: $columnWidth, in: Setting.minColumnWidth...max(maxColumnWidth, Setting.minColumnWidth + 1))
            Text("Taille du texte")
            Slider(value: $fontSize, in: Setting.fontSizeRange)
            Button("OK", action: onDone)
                .buttonStyle(.borderedProminent)
        }
        .font(.callout)
        .padding()
        .frame(width: 220)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .environment(\.colorScheme, .dark)
    }
}
