import SwiftUI

struct TC_TraySatchel: View {

    let blocks: [TC_TileBlock]
    let consumed: [Bool]
    let carryingId: UUID?
    var onPickUp: (UUID, CGPoint) -> Void
    var onDragChanged: (UUID, CGPoint) -> Void
    var onDragEnded: (UUID, CGPoint) -> Void

    var body: some View {
        GeometryReader { geo in
            let slotWidth = (geo.size.width - CGFloat(blocks.count - 1) * 14) / CGFloat(max(1, blocks.count))
            HStack(spacing: 14) {
                ForEach(Array(blocks.enumerated()), id: \.element.id) { pair in
                    slot(for: pair.element,
                         used: index(of: pair.element.id).flatMap { consumed.indices.contains($0) ? consumed[$0] : false } ?? false,
                         maxSize: CGSize(width: slotWidth,
                                         height: geo.size.height))
                }
            }
        }
        .frame(height: 120)
    }

    private func index(of id: UUID) -> Int? {
        blocks.firstIndex(where: { $0.id == id })
    }

    private func slot(for block: TC_TileBlock, used: Bool, maxSize: CGSize) -> some View {
        let span = block.span
        let columns = max(1, span.width)
        let rows = max(1, span.height)
        let cell = min(maxSize.width / CGFloat(columns + 1),
                       maxSize.height / CGFloat(rows + 1))
        let safe = max(18, cell * 0.85)

        return ZStack {
            RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusMedium)
                .fill(Color.tc(TC_AtelierLore.Palette.backdropWood, alpha: 0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusMedium)
                        .stroke(Color.tc(TC_AtelierLore.Palette.gold, alpha: used ? 0.05 : 0.32),
                                lineWidth: 1)
                )

            if !used {
                TC_TileBlockSketch(block: block, cellSide: safe)
                    .opacity(carryingId == block.id ? 0.35 : 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if carryingId == nil {
                        onPickUp(block.id, value.location)
                    } else if carryingId == block.id {
                        onDragChanged(block.id, value.location)
                    }
                }
                .onEnded { value in
                    onDragEnded(block.id, value.location)
                }
        )
        .disabled(used)
    }
}

struct TC_TileBlockSketch: View {
    let block: TC_TileBlock
    let cellSide: CGFloat

    var body: some View {
        let span = block.span
        ZStack(alignment: .topLeading) {
            ForEach(block.cells, id: \.self) { cell in
                Image(cell.motif.assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: cellSide, height: cellSide)
                    .background(
                        RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusSmall)
                            .fill(Color.tc(TC_AtelierLore.Palette.parchmentWarm))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: TC_AtelierLore.Layout.cornerRadiusSmall)
                            .stroke(Color.tc(TC_AtelierLore.Palette.inkSoft, alpha: 0.35), lineWidth: 0.8)
                    )
                    .offset(x: CGFloat(cell.localOffset.column) * (cellSide + 2),
                            y: CGFloat(cell.localOffset.row) * (cellSide + 2))
            }
        }
        .frame(width: CGFloat(span.width) * (cellSide + 2) - 2,
               height: CGFloat(span.height) * (cellSide + 2) - 2,
               alignment: .topLeading)
    }
}
