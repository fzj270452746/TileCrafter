import Foundation

enum TC_CraftedPattern: Hashable {
    case pair(TC_TileMotif)
    case triplet(TC_TileMotif)
    case quad(TC_TileMotif)
    case sequence(TC_Suit, [Int])

    var bounty: Int {
        switch self {
        case .pair:     return TC_AtelierLore.Scoring.pairBonus
        case .triplet:  return TC_AtelierLore.Scoring.tripletBonus
        case .quad:     return TC_AtelierLore.Scoring.quadBonus
        case .sequence: return TC_AtelierLore.Scoring.sequenceBonus
        }
    }

    var headline: String {
        switch self {
        case .pair:     return "Pair"
        case .triplet:  return "Triplet"
        case .quad:     return "Kong"
        case .sequence: return "Run"
        }
    }
}

struct TC_PatternHit: Hashable {
    let pattern: TC_CraftedPattern
    let coords: [TC_GridCoord]
}

enum TC_PatternForge {

    static func detect(in lattice: TC_GridLattice,
                       seedCoords: Set<TC_GridCoord>) -> [TC_PatternHit] {
        var hits: [TC_PatternHit] = []
        var consumed: Set<TC_GridCoord> = []

        let quadHits = scanRepeats(in: lattice, length: 4, seedCoords: seedCoords)
        for hit in quadHits where !fullyConsumed(hit.coords, by: consumed) {
            hits.append(hit)
            consumed.formUnion(hit.coords)
        }

        let tripletHits = scanRepeats(in: lattice, length: 3, seedCoords: seedCoords)
        for hit in tripletHits where !fullyConsumed(hit.coords, by: consumed) {
            hits.append(hit)
            consumed.formUnion(hit.coords)
        }

        let runHits = scanRuns(in: lattice, seedCoords: seedCoords)
        for hit in runHits where !fullyConsumed(hit.coords, by: consumed) {
            hits.append(hit)
            consumed.formUnion(hit.coords)
        }

        let pairHits = scanRepeats(in: lattice, length: 2, seedCoords: seedCoords)
        for hit in pairHits where !fullyConsumed(hit.coords, by: consumed) {
            hits.append(hit)
            consumed.formUnion(hit.coords)
        }

        return hits
    }

    private static func fullyConsumed(_ coords: [TC_GridCoord], by consumed: Set<TC_GridCoord>) -> Bool {
        for coord in coords where !consumed.contains(coord) { return false }
        return true
    }

    private static func segmentTouchesSeed(_ coords: [TC_GridCoord],
                                           seedCoords: Set<TC_GridCoord>) -> Bool {
        for coord in coords where seedCoords.contains(coord) { return true }
        return false
    }

    private static func scanRepeats(in lattice: TC_GridLattice,
                                    length: Int,
                                    seedCoords: Set<TC_GridCoord>) -> [TC_PatternHit] {
        guard length >= 2 else { return [] }
        var output: [TC_PatternHit] = []

        for row in 0..<lattice.rows {
            for column in 0..<(lattice.columns - length + 1) {
                let segment = (0..<length).map { TC_GridCoord(column: column + $0, row: row) }
                guard segmentTouchesSeed(segment, seedCoords: seedCoords) else { continue }
                if let motif = uniformMotif(at: segment, in: lattice) {
                    output.append(TC_PatternHit(pattern: pattern(forRepeat: motif, length: length),
                                                coords: segment))
                }
            }
        }

        for column in 0..<lattice.columns {
            for row in 0..<(lattice.rows - length + 1) {
                let segment = (0..<length).map { TC_GridCoord(column: column, row: row + $0) }
                guard segmentTouchesSeed(segment, seedCoords: seedCoords) else { continue }
                if let motif = uniformMotif(at: segment, in: lattice) {
                    output.append(TC_PatternHit(pattern: pattern(forRepeat: motif, length: length),
                                                coords: segment))
                }
            }
        }

        return output
    }

    private static func pattern(forRepeat motif: TC_TileMotif, length: Int) -> TC_CraftedPattern {
        switch length {
        case 4:  return .quad(motif)
        case 3:  return .triplet(motif)
        default: return .pair(motif)
        }
    }

    private static func uniformMotif(at coords: [TC_GridCoord],
                                     in lattice: TC_GridLattice) -> TC_TileMotif? {
        guard let first = coords.first,
              let firstSlot = lattice.slot(at: first),
              let firstMotif = firstSlot.motif,
              !firstSlot.isFrozen else { return nil }
        for coord in coords.dropFirst() {
            guard let slot = lattice.slot(at: coord),
                  let motif = slot.motif,
                  motif == firstMotif,
                  !slot.isFrozen else { return nil }
        }
        return firstMotif
    }

    private static func scanRuns(in lattice: TC_GridLattice,
                                 seedCoords: Set<TC_GridCoord>) -> [TC_PatternHit] {
        var output: [TC_PatternHit] = []
        let lengths = [4, 3]

        for length in lengths {
            for row in 0..<lattice.rows {
                for column in 0..<(lattice.columns - length + 1) {
                    let segment = (0..<length).map { TC_GridCoord(column: column + $0, row: row) }
                    guard segmentTouchesSeed(segment, seedCoords: seedCoords) else { continue }
                    if let hit = runHit(over: segment, in: lattice) { output.append(hit) }
                }
            }
            for column in 0..<lattice.columns {
                for row in 0..<(lattice.rows - length + 1) {
                    let segment = (0..<length).map { TC_GridCoord(column: column, row: row + $0) }
                    guard segmentTouchesSeed(segment, seedCoords: seedCoords) else { continue }
                    if let hit = runHit(over: segment, in: lattice) { output.append(hit) }
                }
            }
        }

        return output
    }

    private static func runHit(over coords: [TC_GridCoord],
                               in lattice: TC_GridLattice) -> TC_PatternHit? {
        guard let first = coords.first,
              let firstSlot = lattice.slot(at: first),
              let firstMotif = firstSlot.motif,
              firstMotif.isNumbered,
              !firstSlot.isFrozen else { return nil }

        var ranks: [Int] = [firstMotif.rank]
        let suit = firstMotif.suit

        for coord in coords.dropFirst() {
            guard let slot = lattice.slot(at: coord),
                  let motif = slot.motif,
                  motif.isNumbered,
                  motif.suit == suit,
                  !slot.isFrozen else { return nil }
            ranks.append(motif.rank)
        }

        let sortedAscending = ranks == ranks.sorted()
        let sortedDescending = ranks == ranks.sorted(by: >)
        guard sortedAscending || sortedDescending else { return nil }

        let ordered = sortedAscending ? ranks : ranks.reversed()
        for index in 1..<ordered.count where ordered[index] - ordered[index - 1] != 1 {
            return nil
        }

        return TC_PatternHit(pattern: .sequence(suit, Array(ordered)), coords: coords)
    }
}
