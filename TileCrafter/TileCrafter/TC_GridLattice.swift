import Foundation

struct TC_GridSlot: Hashable, Codable {
    var motif: TC_TileMotif?
    var power: TC_TilePower
    var isFrozen: Bool
    var spawnedAt: Int

    static let empty = TC_GridSlot(motif: nil, power: .plain, isFrozen: false, spawnedAt: 0)

    var isOccupied: Bool { motif != nil }
}

struct TC_GridBarrier: Hashable, Codable {
    var hp: Int
}

struct TC_GridLattice: Hashable {
    var slots: [[TC_GridSlot]]
    var barriers: [TC_GridCoord: TC_GridBarrier]
    let columns: Int
    let rows: Int

    init(columns: Int = TC_AtelierLore.Grid.columns,
         rows: Int = TC_AtelierLore.Grid.rows) {
        self.columns = columns
        self.rows = rows
        self.slots = Array(repeating: Array(repeating: .empty, count: columns), count: rows)
        self.barriers = [:]
    }

    func slot(at coord: TC_GridCoord) -> TC_GridSlot? {
        guard contains(coord) else { return nil }
        return slots[coord.row][coord.column]
    }

    func contains(_ coord: TC_GridCoord) -> Bool {
        coord.column >= 0 && coord.column < columns &&
        coord.row    >= 0 && coord.row    < rows
    }

    func hasBarrier(at coord: TC_GridCoord) -> Bool {
        barriers[coord] != nil
    }

    func canHost(_ block: TC_TileBlock, at origin: TC_GridCoord) -> Bool {
        for foot in block.footprint(origin: origin) {
            guard contains(foot) else { return false }
            guard slots[foot.row][foot.column].motif == nil else { return false }
            guard barriers[foot] == nil else { return false }
        }
        return true
    }

    func anyValidOrigin(for block: TC_TileBlock) -> Bool {
        for r in 0..<rows {
            for c in 0..<columns {
                if canHost(block, at: TC_GridCoord(column: c, row: r)) { return true }
            }
        }
        return false
    }

    mutating func install(_ block: TC_TileBlock,
                          at origin: TC_GridCoord,
                          turn: Int) -> [TC_GridCoord]? {
        guard canHost(block, at: origin) else { return nil }
        var planted: [TC_GridCoord] = []
        for cell in block.cells {
            let target = origin.offset(cell.localOffset)
            slots[target.row][target.column] = TC_GridSlot(
                motif: cell.motif,
                power: cell.power,
                isFrozen: cell.power == .frozenIce,
                spawnedAt: turn
            )
            planted.append(target)
        }
        return planted
    }

    mutating func vacate(_ coords: Set<TC_GridCoord>) {
        for coord in coords where contains(coord) {
            slots[coord.row][coord.column] = .empty
        }
    }

    mutating func damageBarriers(adjacentTo vacated: Set<TC_GridCoord>) -> [TC_GridCoord] {
        let deltas = [
            TC_GridCoord(column: 0, row: -1),
            TC_GridCoord(column: 0, row:  1),
            TC_GridCoord(column: -1, row: 0),
            TC_GridCoord(column:  1, row: 0)
        ]
        var destroyed: [TC_GridCoord] = []
        var damaged: Set<TC_GridCoord> = []
        for coord in vacated {
            for delta in deltas {
                let neighbor = coord.offset(delta)
                guard barriers[neighbor] != nil, !damaged.contains(neighbor) else { continue }
                damaged.insert(neighbor)
                barriers[neighbor]!.hp -= 1
                if barriers[neighbor]!.hp <= 0 {
                    barriers.removeValue(forKey: neighbor)
                    destroyed.append(neighbor)
                }
            }
        }
        return destroyed
    }

    var allBarriersCleared: Bool { barriers.isEmpty }

    func occupiedCount() -> Int {
        var sum = 0
        for row in slots { for slot in row where slot.isOccupied { sum += 1 } }
        return sum
    }

    func occupancyRatio() -> Double {
        let total = columns * rows
        guard total > 0 else { return 0 }
        return Double(occupiedCount()) / Double(total)
    }

    func allOccupiedCoords() -> [TC_GridCoord] {
        var coords: [TC_GridCoord] = []
        for r in 0..<rows {
            for c in 0..<columns where slots[r][c].isOccupied {
                coords.append(TC_GridCoord(column: c, row: r))
            }
        }
        return coords
    }
}
