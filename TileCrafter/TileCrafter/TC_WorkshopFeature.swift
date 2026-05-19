import Combine
import CoreGraphics
import Foundation

enum TC_DragPhase: Equatable {
    case idle
    case carrying(blockId: UUID, fingerPoint: CGPoint, hover: TC_GridCoord?)
}

enum TC_LifecyclePhase: Equatable {
    case prelude
    case crafting
    case verdictDefeat
    case verdictTriumph
    case paused
}

struct TC_PulseFlash: Equatable {
    let coord: TC_GridCoord
    let pattern: TC_CraftedPattern
    let bornAt: Date
}

struct TC_FloatingScore: Identifiable, Equatable {
    let id: UUID
    let label: String
    let coord: TC_GridCoord
    let bornAt: Date
}

struct TC_WorkshopState: Equatable {
    var mode: TC_GameMode
    var lattice: TC_GridLattice
    var tray: [TC_TileBlock]
    var trayConsumed: [Bool]
    var score: Int
    var bestScore: Int
    var comboDepth: Int
    var lastComboBounty: Int
    var totalChains: Int
    var totalCascades: Int
    var turnIndex: Int
    var clockRemaining: TimeInterval
    var lifecycle: TC_LifecyclePhase
    var dragPhase: TC_DragPhase
    var pendingPulses: [TC_PulseFlash]
    var floatingScores: [TC_FloatingScore]
    var hazardLevel: Double
    var lastVerdictHeadline: String
    var sfxOn: Bool
    var hapticOn: Bool
    var puzzleRound: Int

    static func == (lhs: TC_WorkshopState, rhs: TC_WorkshopState) -> Bool {
        lhs.mode == rhs.mode &&
        lhs.score == rhs.score &&
        lhs.bestScore == rhs.bestScore &&
        lhs.comboDepth == rhs.comboDepth &&
        lhs.turnIndex == rhs.turnIndex &&
        lhs.lifecycle == rhs.lifecycle &&
        lhs.dragPhase == rhs.dragPhase &&
        lhs.tray == rhs.tray &&
        lhs.trayConsumed == rhs.trayConsumed &&
        lhs.lattice == rhs.lattice &&
        lhs.pendingPulses == rhs.pendingPulses &&
        lhs.floatingScores == rhs.floatingScores &&
        lhs.hazardLevel == rhs.hazardLevel &&
        lhs.clockRemaining == rhs.clockRemaining &&
        lhs.totalChains == rhs.totalChains &&
        lhs.totalCascades == rhs.totalCascades &&
        lhs.lastComboBounty == rhs.lastComboBounty &&
        lhs.lastVerdictHeadline == rhs.lastVerdictHeadline &&
        lhs.sfxOn == rhs.sfxOn &&
        lhs.hapticOn == rhs.hapticOn &&
        lhs.puzzleRound == rhs.puzzleRound
    }
}

enum TC_WorkshopAction: Equatable {
    case onAppear(mode: TC_GameMode, savedBest: Int, sfxOn: Bool, hapticOn: Bool)
    case freshTrayLoaded([TC_TileBlock])
    case beginDrag(blockId: UUID, fingerPoint: CGPoint)
    case dragMoved(fingerPoint: CGPoint, hover: TC_GridCoord?)
    case releaseDrag(at: TC_GridCoord?)
    case finishCascade(outcome: TC_CascadeOutcome, finalLattice: TC_GridLattice)
    case timerTick(delta: TimeInterval)
    case requestPause
    case resume
    case requestRestart
    case advancePuzzleRound
    case clearPulses
    case clearFloating(id: UUID)
    case verdictAcknowledged
    case persistBest(Int)
    case toggleSfx
    case toggleHaptic

    static func == (lhs: TC_WorkshopAction, rhs: TC_WorkshopAction) -> Bool {
        switch (lhs, rhs) {
        case (.onAppear(let a1, let a2, let a3, let a4), .onAppear(let b1, let b2, let b3, let b4)):
            return a1 == b1 && a2 == b2 && a3 == b3 && a4 == b4
        case (.freshTrayLoaded(let a), .freshTrayLoaded(let b)):
            return a == b
        case (.beginDrag(let a1, let a2), .beginDrag(let b1, let b2)):
            return a1 == b1 && a2 == b2
        case (.dragMoved(let a1, let a2), .dragMoved(let b1, let b2)):
            return a1 == b1 && a2 == b2
        case (.releaseDrag(let a), .releaseDrag(let b)):
            return a == b
        case (.finishCascade, .finishCascade):
            return false
        case (.timerTick(let a), .timerTick(let b)):
            return a == b
        case (.requestPause, .requestPause),
             (.resume, .resume),
             (.requestRestart, .requestRestart),
             (.advancePuzzleRound, .advancePuzzleRound),
             (.clearPulses, .clearPulses),
             (.verdictAcknowledged, .verdictAcknowledged),
             (.toggleSfx, .toggleSfx),
             (.toggleHaptic, .toggleHaptic):
            return true
        case (.clearFloating(let a), .clearFloating(let b)):
            return a == b
        case (.persistBest(let a), .persistBest(let b)):
            return a == b
        default: return false
        }
    }
}

struct TC_WorkshopFeature: TC_Feature {
    typealias State = TC_WorkshopState
    typealias Action = TC_WorkshopAction

    static func makeInitial(mode: TC_GameMode) -> TC_WorkshopState {
        let ritual = TC_RitualKiln.make(for: mode)
        return TC_WorkshopState(
            mode: mode,
            lattice: ritual.openingLattice(round: 0),
            tray: [],
            trayConsumed: Array(repeating: false, count: TC_AtelierLore.Grid.traySize),
            score: 0,
            bestScore: 0,
            comboDepth: 0,
            lastComboBounty: 0,
            totalChains: 0,
            totalCascades: 0,
            turnIndex: 0,
            clockRemaining: ritual.timeLimit() ?? 0,
            lifecycle: .prelude,
            dragPhase: .idle,
            pendingPulses: [],
            floatingScores: [],
            hazardLevel: 0,
            lastVerdictHeadline: "",
            sfxOn: true,
            hapticOn: true,
            puzzleRound: 0
        )
    }

    static func reduce(state: inout TC_WorkshopState,
                       action: TC_WorkshopAction) -> TC_Effect<TC_WorkshopAction> {
        switch action {
        case .onAppear(let mode, let savedBest, let sfxOn, let hapticOn):
            let ritual = TC_RitualKiln.make(for: mode)
            state.mode = mode
            state.bestScore = savedBest
            state.sfxOn = sfxOn
            state.hapticOn = hapticOn
            state.lattice = ritual.openingLattice(round: state.puzzleRound)
            state.lifecycle = .crafting
            state.clockRemaining = ritual.timeLimit() ?? 0
            return spawnEffect(for: ritual)

        case .freshTrayLoaded(let blocks):
            state.tray = blocks
            state.trayConsumed = Array(repeating: false, count: blocks.count)
            return checkDeadlock(state: &state)

        case .beginDrag(let blockId, let point):
            guard state.lifecycle == .crafting else { return .none }
            state.dragPhase = .carrying(blockId: blockId, fingerPoint: point, hover: nil)
            return .none

        case .dragMoved(let point, let hover):
            guard case .carrying(let blockId, _, _) = state.dragPhase else { return .none }
            state.dragPhase = .carrying(blockId: blockId, fingerPoint: point, hover: hover)
            return .none

        case .releaseDrag(let coord):
            return performRelease(state: &state, coord: coord)

        case .finishCascade(let outcome, let finalLattice):
            return finalizeCascade(state: &state, outcome: outcome, finalLattice: finalLattice)

        case .timerTick(let delta):
            return tickClock(state: &state, delta: delta)

        case .requestPause:
            if state.lifecycle == .crafting { state.lifecycle = .paused }
            return .none

        case .resume:
            if state.lifecycle == .paused { state.lifecycle = .crafting }
            return .none

        case .requestRestart:
            let mode = state.mode
            let saved = state.bestScore
            let sfx = state.sfxOn
            let haptic = state.hapticOn
            state = makeInitial(mode: mode)
            state.bestScore = saved
            state.sfxOn = sfx
            state.hapticOn = haptic
            return .send(.onAppear(mode: mode, savedBest: saved, sfxOn: sfx, hapticOn: haptic))

        case .advancePuzzleRound:
            let mode = state.mode
            let saved = state.bestScore
            let sfx = state.sfxOn
            let haptic = state.hapticOn
            let nextRound = state.puzzleRound + 1
            let score = state.score
            let totalChains = state.totalChains
            let totalCascades = state.totalCascades
            state = makeInitial(mode: mode)
            state.bestScore = saved
            state.sfxOn = sfx
            state.hapticOn = haptic
            state.puzzleRound = nextRound
            state.score = score
            state.totalChains = totalChains
            state.totalCascades = totalCascades
            return .send(.onAppear(mode: mode, savedBest: saved, sfxOn: sfx, hapticOn: haptic))

        case .clearPulses:
            state.pendingPulses.removeAll()
            return .none

        case .clearFloating(let id):
            state.floatingScores.removeAll { $0.id == id }
            return .none

        case .verdictAcknowledged:
            return .send(.requestRestart)

        case .persistBest:
            return .none

        case .toggleSfx:
            state.sfxOn.toggle()
            return .none

        case .toggleHaptic:
            state.hapticOn.toggle()
            return .none
        }
    }

    private static func performRelease(state: inout TC_WorkshopState,
                                       coord: TC_GridCoord?) -> TC_Effect<TC_WorkshopAction> {
        guard case .carrying(let blockId, _, _) = state.dragPhase else { return .none }
        state.dragPhase = .idle

        guard let target = coord,
              let trayIndex = state.tray.firstIndex(where: { $0.id == blockId }),
              !state.trayConsumed[trayIndex] else { return .none }

        let block = state.tray[trayIndex]
        guard state.lattice.canHost(block, at: target) else { return .none }
        guard let planted = state.lattice.install(block, at: target, turn: state.turnIndex) else { return .none }

        state.trayConsumed[trayIndex] = true
        let placementScore = TC_AtelierLore.Scoring.placementBase * block.cells.count
        state.score += placementScore
        state.turnIndex += 1
        state.hazardLevel = state.lattice.occupancyRatio()

        let (settledLattice, outcome) = TC_CascadeResolver.resolve(
            initialLattice: state.lattice,
            seedCoords: Set(planted),
            comboMultiplierStart: 1
        )

        return .delayed(.finishCascade(outcome: outcome, finalLattice: settledLattice),
                        by: TC_AtelierLore.Cadence.placementSettle)
    }

    private static func finalizeCascade(state: inout TC_WorkshopState,
                                        outcome: TC_CascadeOutcome,
                                        finalLattice: TC_GridLattice) -> TC_Effect<TC_WorkshopAction> {
        state.lattice = finalLattice
        state.score += outcome.totalBounty
        state.lastComboBounty = outcome.totalBounty
        state.comboDepth = outcome.comboDepth
        state.totalChains += outcome.rounds.count
        state.totalCascades += outcome.comboDepth

        var pulses: [TC_PulseFlash] = []
        var floats: [TC_FloatingScore] = []
        for round in outcome.rounds {
            for hit in round.hits {
                let stamp = Date()
                if let firstCoord = hit.coords.first {
                    pulses.append(TC_PulseFlash(coord: firstCoord, pattern: hit.pattern, bornAt: stamp))
                    floats.append(TC_FloatingScore(
                        id: UUID(),
                        label: "+\(hit.pattern.bounty)",
                        coord: firstCoord,
                        bornAt: stamp
                    ))
                }
            }
        }
        state.pendingPulses = pulses
        state.floatingScores.append(contentsOf: floats)

        state.hazardLevel = state.lattice.occupancyRatio()

        if state.mode == .puzzle && state.lattice.allBarriersCleared {
            let round = state.puzzleRound + 1
            state.lastVerdictHeadline = "Round \(round) Cleared — \(state.score) pts"
            state.lifecycle = .verdictTriumph
            if state.score > state.bestScore {
                state.bestScore = state.score
                return .send(.persistBest(state.bestScore))
            }
            return .none
        }

        let trayConsumedAll = state.trayConsumed.allSatisfy { $0 }
        var refillEffects: [TC_Effect<TC_WorkshopAction>] = []
        if trayConsumedAll {
            let ritual = TC_RitualKiln.make(for: state.mode)
            refillEffects.append(spawnEffect(for: ritual))
        }

        if state.score > state.bestScore {
            state.bestScore = state.score
            refillEffects.append(.send(.persistBest(state.bestScore)))
        }

        let deadlockEffect = checkDeadlock(state: &state)
        return .merge(refillEffects + [deadlockEffect])
    }

    private static func tickClock(state: inout TC_WorkshopState,
                                  delta: TimeInterval) -> TC_Effect<TC_WorkshopAction> {
        guard state.lifecycle == .crafting else { return .none }
        let ritual = TC_RitualKiln.make(for: state.mode)
        guard ritual.timeLimit() != nil else { return .none }
        state.clockRemaining = max(0, state.clockRemaining - delta)
        if state.clockRemaining <= 0 {
            state.lifecycle = .verdictTriumph
            state.lastVerdictHeadline = "Time's Up — Final Score \(state.score)"
        }
        return .none
    }

    private static func checkDeadlock(state: inout TC_WorkshopState) -> TC_Effect<TC_WorkshopAction> {
        let ritual = TC_RitualKiln.make(for: state.mode)
        guard !ritual.zenSafety() else { return .none }

        let totalSlots = state.lattice.columns * state.lattice.rows
        let barrierCount = state.lattice.barriers.count
        let isBoardFull = state.lattice.occupiedCount() + barrierCount >= totalSlots

        var anyPlayable = false
        for (index, block) in state.tray.enumerated() where !state.trayConsumed[index] {
            if state.lattice.anyValidOrigin(for: block) { anyPlayable = true; break }
        }

        if isBoardFull && !anyPlayable {
            state.lifecycle = .verdictDefeat
            state.lastVerdictHeadline = "Atelier Sealed — \(state.score) pts"
        }
        return .none
    }

    private static func spawnEffect(for ritual: TC_SessionRitual) -> TC_Effect<TC_WorkshopAction> {
        .fire { dispatch in
            let blocks = ritual.freshTray()
            dispatch(.freshTrayLoaded(blocks))
        }
    }
}
