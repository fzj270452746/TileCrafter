import Foundation

protocol TC_SessionRitual: AnyObject {
    var mode: TC_GameMode { get }
    func makeSpawner() -> TC_BlockArtisan
    func openingLattice() -> TC_GridLattice
    func openingLattice(round: Int) -> TC_GridLattice
    func turnLimit() -> Int?
    func timeLimit() -> TimeInterval?
    func zenSafety() -> Bool
    func difficulty() -> TC_Difficulty
}

extension TC_SessionRitual {
    func freshTray() -> [TC_TileBlock] {
        makeSpawner().buildBatch(count: TC_AtelierLore.Grid.traySize)
    }

    func openingLattice(round: Int) -> TC_GridLattice {
        openingLattice()
    }
}

final class TC_ClassicRitual: TC_SessionRitual {
    let mode: TC_GameMode = .classic
    func makeSpawner() -> TC_BlockArtisan {
        TC_BlockArtisan()
            .withDifficulty(.normal)
            .withAllowedSuits([.bamboo, .character, .dot])
            .withHonors(true)
    }
    func openingLattice() -> TC_GridLattice { TC_GridLattice() }
    func turnLimit() -> Int? { nil }
    func timeLimit() -> TimeInterval? { nil }
    func zenSafety() -> Bool { false }
    func difficulty() -> TC_Difficulty { .normal }
}

final class TC_PuzzleRitual: TC_SessionRitual {
    let mode: TC_GameMode = .puzzle

    func makeSpawner() -> TC_BlockArtisan {
        TC_BlockArtisan()
            .withDifficulty(.hard)
            .withAllowedSuits([.bamboo, .character, .dot])
            .withHonors(false)
            .withShapePool([.domino, .stripThree, .corner, .stairs, .tee, .square])
    }

    func openingLattice() -> TC_GridLattice {
        openingLattice(round: 0)
    }

    func openingLattice(round: Int) -> TC_GridLattice {
        var lattice = TC_GridLattice()
        let roundSeed = UInt64(bitPattern: Int64(round) &* Int64(bitPattern: TC_AtelierLore.Puzzle.roundSeedMultiplier)) &+ 0x7E57C0DE
        var rng = TC_FixedSeedRng(seed: roundSeed == 0 ? 1 : roundSeed)

        let count = TC_AtelierLore.Puzzle.barrierCount
        var placed: Set<TC_GridCoord> = []
        var attempts = 0
        let maxAttempts = count * 8

        while placed.count < count && attempts < maxAttempts {
            attempts += 1
            let col = Int.random(in: 1..<(TC_AtelierLore.Grid.columns - 1), using: &rng)
            let row = Int.random(in: 1..<(TC_AtelierLore.Grid.rows - 1), using: &rng)
            let coord = TC_GridCoord(column: col, row: row)
            guard !placed.contains(coord) else { continue }
            placed.insert(coord)
            let hp = Int.random(in: TC_AtelierLore.Puzzle.barrierMinHp...TC_AtelierLore.Puzzle.barrierMaxHp, using: &rng)
            lattice.barriers[coord] = TC_GridBarrier(hp: hp)
        }
        return lattice
    }

    func turnLimit() -> Int? { nil }
    func timeLimit() -> TimeInterval? { nil }
    func zenSafety() -> Bool { false }
    func difficulty() -> TC_Difficulty { .hard }
}

final class TC_RushRitual: TC_SessionRitual {
    let mode: TC_GameMode = .rush
    func makeSpawner() -> TC_BlockArtisan {
        TC_BlockArtisan()
            .withDifficulty(.easy)
            .withAllowedSuits([.bamboo, .character, .dot])
            .withHonors(false)
            .withShapePool([.domino, .stripThree, .single, .corner])
    }
    func openingLattice() -> TC_GridLattice { TC_GridLattice() }
    func turnLimit() -> Int? { nil }
    func timeLimit() -> TimeInterval? { TC_AtelierLore.Cadence.rushDuration }
    func zenSafety() -> Bool { false }
    func difficulty() -> TC_Difficulty { .easy }
}

final class TC_ZenRitual: TC_SessionRitual {
    let mode: TC_GameMode = .zen
    func makeSpawner() -> TC_BlockArtisan {
        TC_BlockArtisan()
            .withDifficulty(.easy)
            .withAllowedSuits([.bamboo, .character, .dot])
            .withHonors(true)
    }
    func openingLattice() -> TC_GridLattice { TC_GridLattice() }
    func turnLimit() -> Int? { nil }
    func timeLimit() -> TimeInterval? { nil }
    func zenSafety() -> Bool { true }
    func difficulty() -> TC_Difficulty { .easy }
}

enum TC_RitualKiln {
    static func make(for mode: TC_GameMode) -> TC_SessionRitual {
        switch mode {
        case .classic: return TC_ClassicRitual()
        case .puzzle:  return TC_PuzzleRitual()
        case .rush:    return TC_RushRitual()
        case .zen:     return TC_ZenRitual()
        }
    }
}
