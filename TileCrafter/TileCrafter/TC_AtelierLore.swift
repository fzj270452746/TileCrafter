import CoreGraphics
import Foundation

enum TC_AtelierLore {

    enum Grid {
        static let columns: Int = 8
        static let rows: Int = 8
        static let traySize: Int = 3
        static let hazardThresholdRatio: Double = 0.78
    }

    enum Cadence {
        static let frameInterval: TimeInterval = 1.0 / 60.0
        static let cascadeDelay: TimeInterval = 0.22
        static let highlightLinger: TimeInterval = 0.18
        static let placementSettle: TimeInterval = 0.12
        static let rushDuration: TimeInterval = 90.0
    }

    enum Scoring {
        static let placementBase: Int = 4
        static let pairBonus: Int = 40
        static let sequenceBonus: Int = 120
        static let tripletBonus: Int = 160
        static let quadBonus: Int = 320
        static let comboMultiplierStep: Int = 1
        static let clearBoardBounty: Int = 600
    }

    enum Combo {
        static let mildThreshold: Int = 2
        static let fierceThreshold: Int = 5
        static let blazingThreshold: Int = 10
    }

    enum Spawn {
        static let jokerChanceEasy: Double = 0.05
        static let jokerChanceNormal: Double = 0.025
        static let jokerChanceHard: Double = 0.01
        static let powerTileChance: Double = 0.06
        static let suitsForEasy: Int = 2
        static let suitsForNormal: Int = 3
        static let suitsForHard: Int = 3
        static let maxRankSpan: Int = 9
    }

    enum Layout {
        static let boardSidePadding: CGFloat = 18
        static let boardTopGutter: CGFloat = 12
        static let traySidePadding: CGFloat = 16
        static let trayBlockSlotPadding: CGFloat = 10
        static let trayHeightRatio: CGFloat = 0.22
        static let hudHeight: CGFloat = 110
        static let parchmentMaxWidth: CGFloat = 320
        static let cornerRadiusSmall: CGFloat = 8
        static let cornerRadiusMedium: CGFloat = 14
        static let cornerRadiusLarge: CGFloat = 22
        static let tileInnerPaddingRatio: CGFloat = 0.08
        static let zHud: CGFloat = 100
        static let zBackdrop: CGFloat = 0
        static let zBoardGrid: CGFloat = 1
        static let zPlacedTile: CGFloat = 5
        static let zDragging: CGFloat = 50
        static let zTrayBackdrop: CGFloat = 2
        static let zTrayBlock: CGFloat = 6
    }

    enum Palette {
        static let parchmentWarm: UInt32 = 0xF4E4C1
        static let parchmentDeep: UInt32 = 0xD9B98A
        static let inkBrown: UInt32 = 0x4A2E1A
        static let inkSoft: UInt32 = 0x7A5A3C
        static let lacquerRed: UInt32 = 0xB4332A
        static let jadeGreen: UInt32 = 0x4F8A6B
        static let gold: UInt32 = 0xC7902E
        static let backdropWood: UInt32 = 0x2A1A10
        static let backdropFelt: UInt32 = 0x1B3A2A
        static let hazardCrimson: UInt32 = 0x8C1F18
        static let slotIdle: UInt32 = 0xE8D3A6
        static let slotForbidden: UInt32 = 0x8B463C
        static let slotInviting: UInt32 = 0xF7E7A1
        static let barrierStone: UInt32 = 0x5C4A3A
        static let barrierCrack: UInt32 = 0x8C7060
    }

    enum Puzzle {
        static let barrierCount: Int = 6
        static let barrierMaxHp: Int = 3
        static let barrierMinHp: Int = 1
        static let roundSeedMultiplier: UInt64 = 0x9E3779B97F4A7C15
    }

    enum Persistence {
        static let highScoreKeyPrefix: String = "tc.highscore."
        static let bgmEnabledKey: String = "tc.settings.bgm"
        static let sfxEnabledKey: String = "tc.settings.sfx"
        static let hapticEnabledKey: String = "tc.settings.haptic"
        static let totalChainsKey: String = "tc.stat.chains"
        static let totalCascadesKey: String = "tc.stat.cascades"
        static let totalSessionsKey: String = "tc.stat.sessions"
    }
}

enum TC_GameMode: String, CaseIterable, Codable {
    case classic
    case puzzle
    case rush
    case zen

    var displayTitle: String {
        switch self {
        case .classic: return "Classic Atelier"
        case .puzzle:  return "Puzzle Trial"
        case .rush:    return "Rush Forge"
        case .zen:     return "Zen Garden"
        }
    }

    var blurb: String {
        switch self {
        case .classic: return "Endless crafting. Survive as long as you can."
        case .puzzle:  return "Fixed tiles. Solve the layout."
        case .rush:    return "Beat the clock. Forge faster."
        case .zen:     return "No fail state. Just craft."
        }
    }
}

enum TC_Difficulty {
    case easy
    case normal
    case hard

    var jokerProbability: Double {
        switch self {
        case .easy:   return TC_AtelierLore.Spawn.jokerChanceEasy
        case .normal: return TC_AtelierLore.Spawn.jokerChanceNormal
        case .hard:   return TC_AtelierLore.Spawn.jokerChanceHard
        }
    }

    var suitCount: Int {
        switch self {
        case .easy:   return TC_AtelierLore.Spawn.suitsForEasy
        case .normal: return TC_AtelierLore.Spawn.suitsForNormal
        case .hard:   return TC_AtelierLore.Spawn.suitsForHard
        }
    }
}

enum TC_ComboTier {
    case none
    case mild
    case fierce
    case blazing

    static func tier(forDepth depth: Int) -> TC_ComboTier {
        if depth >= TC_AtelierLore.Combo.blazingThreshold { return .blazing }
        if depth >= TC_AtelierLore.Combo.fierceThreshold  { return .fierce }
        if depth >= TC_AtelierLore.Combo.mildThreshold    { return .mild }
        return .none
    }
}
