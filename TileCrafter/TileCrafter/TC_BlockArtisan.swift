import Foundation

final class TC_BlockArtisan {

    private var difficulty: TC_Difficulty = .normal
    private var allowedSuits: Set<TC_Suit> = [.bamboo, .character, .dot]
    private var enableHonors: Bool = true
    private var shapePool: [TC_BlockSilhouette] = TC_BlockSilhouette.allCases
    private var jokerProbability: Double = TC_AtelierLore.Spawn.jokerChanceNormal
    private var rngSeed: UInt64?

    @discardableResult
    func withDifficulty(_ value: TC_Difficulty) -> TC_BlockArtisan {
        difficulty = value
        jokerProbability = value.jokerProbability
        return self
    }

    @discardableResult
    func withAllowedSuits(_ suits: Set<TC_Suit>) -> TC_BlockArtisan {
        allowedSuits = suits
        return self
    }

    @discardableResult
    func withHonors(_ enabled: Bool) -> TC_BlockArtisan {
        enableHonors = enabled
        return self
    }

    @discardableResult
    func withShapePool(_ pool: [TC_BlockSilhouette]) -> TC_BlockArtisan {
        shapePool = pool
        return self
    }

    @discardableResult
    func withSeed(_ seed: UInt64?) -> TC_BlockArtisan {
        rngSeed = seed
        return self
    }

    func build() -> TC_TileBlock {
        var generator = makeGenerator()
        let silhouette = shapePool.randomElement(using: &generator) ?? .single
        let cells = synthesizeCells(for: silhouette, generator: &generator)
        return TC_TileBlock(id: UUID(), silhouette: silhouette, cells: cells)
    }

    func buildBatch(count: Int) -> [TC_TileBlock] {
        (0..<count).map { _ in build() }
    }

    private func synthesizeCells(for silhouette: TC_BlockSilhouette,
                                 generator: inout TC_FixedSeedRng) -> [TC_TileCell] {
        let offsets = silhouette.offsets
        let suit = pickSuit(generator: &generator)
        let strategy = pickStrategy(for: silhouette, generator: &generator)

        let baseMotifs: [TC_TileMotif]
        switch strategy {
        case .runFriendly:
            baseMotifs = makeRunFriendly(suit: suit, count: offsets.count, generator: &generator)
        case .matched:
            baseMotifs = makeMatched(suit: suit, count: offsets.count, generator: &generator)
        case .scattered:
            baseMotifs = makeScattered(suit: suit, count: offsets.count, generator: &generator)
        }

        var cells: [TC_TileCell] = []
        for (index, offset) in offsets.enumerated() {
            let motif = baseMotifs[index]
            let power = pickPower(generator: &generator)
            cells.append(TC_TileCell(motif: motif, power: power, localOffset: offset))
        }
        return cells
    }

    private enum SpawnStrategy { case runFriendly, matched, scattered }

    private func pickStrategy(for silhouette: TC_BlockSilhouette,
                              generator: inout TC_FixedSeedRng) -> SpawnStrategy {
        switch silhouette {
        case .single:
            return .matched
        case .domino:
            return Double.random(in: 0...1, using: &generator) < 0.55 ? .runFriendly : .matched
        case .stripThree:
            return Double.random(in: 0...1, using: &generator) < 0.7 ? .runFriendly : .matched
        case .square, .corner, .stairs, .tee:
            let dice = Double.random(in: 0...1, using: &generator)
            if dice < 0.4 { return .matched }
            if dice < 0.75 { return .runFriendly }
            return .scattered
        }
    }

    private func pickSuit(generator: inout TC_FixedSeedRng) -> TC_Suit {
        let suits = Array(allowedSuits)
        return suits.randomElement(using: &generator) ?? .bamboo
    }

    private func makeRunFriendly(suit: TC_Suit,
                                 count: Int,
                                 generator: inout TC_FixedSeedRng) -> [TC_TileMotif] {
        let span = TC_AtelierLore.Spawn.maxRankSpan
        let safeCount = max(1, min(count, span))
        let maxStart = max(1, span - safeCount + 1)
        let start = Int.random(in: 1...maxStart, using: &generator)
        var ranks: [Int] = (0..<count).map { ((start + $0 - 1) % span) + 1 }
        if Double.random(in: 0...1, using: &generator) < 0.35 {
            ranks.shuffle(using: &generator)
        }
        return ranks.map { TC_TileMotif.numbered(suit, $0) }
    }

    private func makeMatched(suit: TC_Suit,
                             count: Int,
                             generator: inout TC_FixedSeedRng) -> [TC_TileMotif] {
        let span = TC_AtelierLore.Spawn.maxRankSpan
        let rank = Int.random(in: 1...span, using: &generator)
        return Array(repeating: TC_TileMotif.numbered(suit, rank), count: count)
    }

    private func makeScattered(suit: TC_Suit,
                               count: Int,
                               generator: inout TC_FixedSeedRng) -> [TC_TileMotif] {
        let span = TC_AtelierLore.Spawn.maxRankSpan
        return (0..<count).map { _ in
            TC_TileMotif.numbered(suit, Int.random(in: 1...span, using: &generator))
        }
    }

    private func pickPower(generator: inout TC_FixedSeedRng) -> TC_TilePower {
        let dice = Double.random(in: 0...1, using: &generator)
        if dice < jokerProbability { return .jokerRed }
        let powerRoll = Double.random(in: 0...1, using: &generator)
        guard powerRoll < TC_AtelierLore.Spawn.powerTileChance, enableHonors else { return .plain }
        let pool: [TC_TilePower] = [.mirrorWhite, .sweepEast, .bombFa, .frozenIce]
        return pool.randomElement(using: &generator) ?? .plain
    }

    private func makeGenerator() -> TC_FixedSeedRng {
        if let seed = rngSeed { return TC_FixedSeedRng(seed: seed) }
        return TC_FixedSeedRng(seed: UInt64.random(in: 1...UInt64.max))
    }
}

struct TC_FixedSeedRng: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0xDEADBEEF : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z &>> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z &>> 27)) &* 0x94D049BB133111EB
        return z ^ (z &>> 31)
    }
}
