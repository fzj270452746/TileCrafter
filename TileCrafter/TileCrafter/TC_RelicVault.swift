import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

@available(iOS 17.0, *)
@Model
final class TC_RelicEntry {
    var modeKey: String
    var bestScore: Int
    var totalChains: Int
    var totalCascades: Int
    var totalSessions: Int
    var updatedAt: Date

    init(modeKey: String,
         bestScore: Int,
         totalChains: Int = 0,
         totalCascades: Int = 0,
         totalSessions: Int = 0,
         updatedAt: Date = .init()) {
        self.modeKey = modeKey
        self.bestScore = bestScore
        self.totalChains = totalChains
        self.totalCascades = totalCascades
        self.totalSessions = totalSessions
        self.updatedAt = updatedAt
    }
}

final class TC_RelicVault {

    private let defaults = UserDefaults.standard

    func loadBest(for mode: TC_GameMode) -> Int {
        defaults.integer(forKey: TC_AtelierLore.Persistence.highScoreKeyPrefix + mode.rawValue)
    }

    func saveBest(_ score: Int, for mode: TC_GameMode) {
        let key = TC_AtelierLore.Persistence.highScoreKeyPrefix + mode.rawValue
        let existing = defaults.integer(forKey: key)
        if score > existing { defaults.set(score, forKey: key) }
    }

    func loadTotals() -> (chains: Int, cascades: Int, sessions: Int) {
        let chains = defaults.integer(forKey: TC_AtelierLore.Persistence.totalChainsKey)
        let cascades = defaults.integer(forKey: TC_AtelierLore.Persistence.totalCascadesKey)
        let sessions = defaults.integer(forKey: TC_AtelierLore.Persistence.totalSessionsKey)
        return (chains, cascades, sessions)
    }

    func appendTotals(chains: Int, cascades: Int) {
        let snapshot = loadTotals()
        defaults.set(snapshot.chains + chains, forKey: TC_AtelierLore.Persistence.totalChainsKey)
        defaults.set(snapshot.cascades + cascades, forKey: TC_AtelierLore.Persistence.totalCascadesKey)
        defaults.set(snapshot.sessions + 1, forKey: TC_AtelierLore.Persistence.totalSessionsKey)
    }

    func loadSfxOn() -> Bool {
        if defaults.object(forKey: TC_AtelierLore.Persistence.sfxEnabledKey) == nil { return true }
        return defaults.bool(forKey: TC_AtelierLore.Persistence.sfxEnabledKey)
    }

    func loadBgmOn() -> Bool {
        if defaults.object(forKey: TC_AtelierLore.Persistence.bgmEnabledKey) == nil { return true }
        return defaults.bool(forKey: TC_AtelierLore.Persistence.bgmEnabledKey)
    }

    func loadHapticOn() -> Bool {
        if defaults.object(forKey: TC_AtelierLore.Persistence.hapticEnabledKey) == nil { return true }
        return defaults.bool(forKey: TC_AtelierLore.Persistence.hapticEnabledKey)
    }

    func saveSfxOn(_ flag: Bool) {
        defaults.set(flag, forKey: TC_AtelierLore.Persistence.sfxEnabledKey)
    }

    func saveBgmOn(_ flag: Bool) {
        defaults.set(flag, forKey: TC_AtelierLore.Persistence.bgmEnabledKey)
    }

    func saveHapticOn(_ flag: Bool) {
        defaults.set(flag, forKey: TC_AtelierLore.Persistence.hapticEnabledKey)
    }
}
