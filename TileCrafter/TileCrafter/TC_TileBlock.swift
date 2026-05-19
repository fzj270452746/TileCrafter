import Foundation

struct TC_GridCoord: Hashable, Codable {
    let column: Int
    let row: Int

    static let origin = TC_GridCoord(column: 0, row: 0)

    func offset(_ delta: TC_GridCoord) -> TC_GridCoord {
        TC_GridCoord(column: column + delta.column, row: row + delta.row)
    }
}

struct TC_TileCell: Hashable, Codable {
    let motif: TC_TileMotif
    let power: TC_TilePower
    let localOffset: TC_GridCoord
}

enum TC_BlockSilhouette: CaseIterable {
    case single
    case domino
    case stripThree
    case corner
    case square
    case stairs
    case tee

    var offsets: [TC_GridCoord] {
        switch self {
        case .single:
            return [TC_GridCoord(column: 0, row: 0)]
        case .domino:
            return [TC_GridCoord(column: 0, row: 0),
                    TC_GridCoord(column: 1, row: 0)]
        case .stripThree:
            return [TC_GridCoord(column: 0, row: 0),
                    TC_GridCoord(column: 1, row: 0),
                    TC_GridCoord(column: 2, row: 0)]
        case .corner:
            return [TC_GridCoord(column: 0, row: 0),
                    TC_GridCoord(column: 0, row: 1),
                    TC_GridCoord(column: 1, row: 1)]
        case .square:
            return [TC_GridCoord(column: 0, row: 0),
                    TC_GridCoord(column: 1, row: 0),
                    TC_GridCoord(column: 0, row: 1),
                    TC_GridCoord(column: 1, row: 1)]
        case .stairs:
            return [TC_GridCoord(column: 0, row: 0),
                    TC_GridCoord(column: 1, row: 0),
                    TC_GridCoord(column: 1, row: 1)]
        case .tee:
            return [TC_GridCoord(column: 0, row: 0),
                    TC_GridCoord(column: 1, row: 0),
                    TC_GridCoord(column: 2, row: 0),
                    TC_GridCoord(column: 1, row: 1)]
        }
    }

    var span: (width: Int, height: Int) {
        let offsets = self.offsets
        let maxColumn = offsets.map(\.column).max() ?? 0
        let maxRow = offsets.map(\.row).max() ?? 0
        return (maxColumn + 1, maxRow + 1)
    }
}

struct TC_TileBlock: Identifiable, Hashable {
    let id: UUID
    let silhouette: TC_BlockSilhouette
    let cells: [TC_TileCell]

    var span: (width: Int, height: Int) { silhouette.span }
    var offsets: [TC_GridCoord] { silhouette.offsets }

    func footprint(origin: TC_GridCoord) -> [TC_GridCoord] {
        offsets.map { origin.offset($0) }
    }
}
