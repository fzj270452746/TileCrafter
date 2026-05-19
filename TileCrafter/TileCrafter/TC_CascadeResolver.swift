import Foundation

struct TC_CascadeRound {
    let hits: [TC_PatternHit]
    let vacated: Set<TC_GridCoord>
    let bounty: Int
    let destroyedBarriers: [TC_GridCoord]
}

struct TC_CascadeOutcome {
    let rounds: [TC_CascadeRound]
    let totalBounty: Int
    let comboDepth: Int
    let clearedBoard: Bool
}

enum TC_CascadeResolver {

    static func resolve(initialLattice: TC_GridLattice,
                        seedCoords: Set<TC_GridCoord>,
                        comboMultiplierStart: Int) -> (TC_GridLattice, TC_CascadeOutcome) {
        var lattice = initialLattice
        var rounds: [TC_CascadeRound] = []
        var totalBounty = 0
        var comboDepth = 0
        let multiplier = comboMultiplierStart

        let hits = TC_PatternForge.detect(in: lattice, seedCoords: seedCoords)
        if !hits.isEmpty {
            var vacated: Set<TC_GridCoord> = []
            var roundBounty = 0
            for hit in hits {
                vacated.formUnion(hit.coords)
                roundBounty += hit.pattern.bounty
            }

            let scaledBounty = roundBounty * max(multiplier, 1)
            totalBounty += scaledBounty
            comboDepth += 1

            lattice.vacate(vacated)
            let destroyed = lattice.damageBarriers(adjacentTo: vacated)

            rounds.append(TC_CascadeRound(hits: hits,
                                          vacated: vacated,
                                          bounty: scaledBounty,
                                          destroyedBarriers: destroyed))
        }

        let cleared = lattice.occupiedCount() == 0
        let bonus = cleared && !rounds.isEmpty ? TC_AtelierLore.Scoring.clearBoardBounty : 0

        let outcome = TC_CascadeOutcome(rounds: rounds,
                                        totalBounty: totalBounty + bonus,
                                        comboDepth: comboDepth,
                                        clearedBoard: cleared)
        return (lattice, outcome)
    }
}
