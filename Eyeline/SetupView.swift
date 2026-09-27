import SwiftUI

// Drawn over the full screen. The Pocket hides the middle of the band, so the user drags its visible edges.
struct SetupHandles: View {
    let size: CGSize
    let band: CGRect
    let column: CGRect
    let side: ColumnSide
    let readingY: Double
    @Binding var bandCenter: Double
    @Binding var bandWidth: Double
    @Binding var leftColumnWidth: Double
    @Binding var rightColumnWidth: Double
    @Binding var readingLine: Double

    @State private var bandAtDragStart: CGRect?
    @State private var widthAtDragStart: Double?
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
            if side != .right {
                columnEdge(.leading, at: column.minX, width: $leftColumnWidth, shown: band.minX - column.minX)
            }
            if side != .left {
                columnEdge(.trailing, at: column.maxX, width: $rightColumnWidth, shown: column.maxX - band.maxX)
            }
            bandEdge(.leading, at: band.minX)
            bandEdge(.trailing, at: band.maxX)
            line
        }
    }

    private func handle(at x: Double, color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: 3)
            .frame(width: 44, height: size.height)
            .contentShape(Rectangle())
            .position(x: x, y: size.height / 2)
    }

    private func bandEdge(_ edge: HorizontalEdge, at x: Double) -> some View {
        handle(at: x, color: .orange)
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

    // The drag starts from the shown width: on a narrow strip it is smaller than the stored one.
    private func columnEdge(_ edge: HorizontalEdge, at x: Double, width: Binding<Double>, shown: Double) -> some View {
        handle(at: x, color: .white)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let start = widthAtDragStart ?? shown
                        widthAtDragStart = start
                        width.wrappedValue = Layout.columnWidth(
                            dragging: edge, from: start, by: value.translation.width, band: band, in: size)
                    }
                    .onEnded { _ in
                        widthAtDragStart = nil
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

// At the top, in two small blocks: the handles run the full screen height, so they stay free below.
struct SetupPanel: View {
    @Binding var columnSide: ColumnSide
    @Binding var fontSize: Double
    @Binding var lineSpacing: Double
    let onDone: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Picker("Côté du texte", selection: $columnSide) {
                    Text("Gauche").tag(ColumnSide.left)
                    Text("Les deux").tag(ColumnSide.both)
                    Text("Droite").tag(ColumnSide.right)
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
                Button("OK", action: onDone)
                    .buttonStyle(.borderedProminent)
            }
            .padding(10)
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
            Spacer()
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
}
