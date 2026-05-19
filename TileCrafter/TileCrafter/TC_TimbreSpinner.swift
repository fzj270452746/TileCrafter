import AVFoundation
import Foundation

enum TC_TimbreAsset: String {
    case place
    case eliminate
    case combo
    case fail
    case button

    var fileBaseName: String { rawValue }
}

final class TC_TimbreSpinner: NSObject {
    private var activePlayers: [AVAudioPlayer] = []
    private var bgmPlayer: AVAudioPlayer?
    private(set) var sfxEnabled: Bool = true
    private(set) var bgmEnabled: Bool = true

    func updatePreferences(sfxOn: Bool, bgmOn: Bool) {
        sfxEnabled = sfxOn
        bgmEnabled = bgmOn
        if !bgmOn { stopBgm() }
    }

    func spin(_ asset: TC_TimbreAsset) {
        guard sfxEnabled else { return }
        guard let url = locateAsset(named: asset.fileBaseName) else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.delegate = self
        activePlayers.append(player)
        player.prepareToPlay()
        player.play()
    }

    func startBgm(named name: String = "atelier_bgm") {
        guard bgmEnabled else { return }
        guard bgmPlayer == nil else { bgmPlayer?.play(); return }
        guard let url = locateAsset(named: name) else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.numberOfLoops = -1
        player.volume = 0.45
        bgmPlayer = player
        player.prepareToPlay()
        player.play()
    }

    func stopBgm() {
        bgmPlayer?.stop()
        bgmPlayer = nil
    }

    private func locateAsset(named name: String) -> URL? {
        let extensions = ["caf", "wav", "m4a", "mp3"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }
}

extension TC_TimbreSpinner: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        activePlayers.removeAll { $0 === player }
    }
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        activePlayers.removeAll { $0 === player }
    }
}
