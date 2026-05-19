import Foundation
import UIKit

final class TC_BannerEnvoy {
    private(set) var bannerCarrier: UIView?

    func registerBanner(_ view: UIView) { bannerCarrier = view }

    func presentInterstitialIfPossible(from host: UIViewController?) {
        guard host != nil else { return }
    }

    func setReady() { }
}
