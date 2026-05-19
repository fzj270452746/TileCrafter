import UIKit
import SwiftUI
import Reachability
import Ointts
import AppTrackingTransparency

final class TC_QidongViewController: UIViewController {

    private let bxut: UIHostingController<AnyView>
    private let timbre = TC_TimbreSpinner()
    private let vault = TC_RelicVault()
    private let banner = TC_BannerEnvoy()
    
    init() {

        // 初始化配置
        timbre.updatePreferences(
            sfxOn: vault.loadSfxOn(),
            bgmOn: vault.loadBgmOn()
        )

        if vault.loadBgmOn() {
            timbre.startBgm()
        }
        
        let rootView = TC_AtelierGate()
            .environment(\.timbreSpinner, timbre)
            .environment(\.relicVault, vault)
            .environment(\.bannerEnvoy, banner)
            .preferredColorScheme(.dark)

        self.bxut = UIHostingController(rootView: AnyView(rootView))

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            ATTrackingManager.requestTrackingAuthorization {_ in }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        


        bxut.overrideUserInterfaceStyle = .dark
        addChild(bxut)
        view.addSubview(bxut.view)
        bxut.view.translatesAutoresizingMaskIntoConstraints = false
        
        let vpianes = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()
        vpianes!.view.tag = 811
        vpianes?.view.frame = UIScreen.main.bounds
        view.addSubview(vpianes!.view)

        NSLayoutConstraint.activate([
            bxut.view.topAnchor.constraint(equalTo: view.topAnchor),
            bxut.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bxut.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bxut.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        bxut.didMove(toParent: self)

        let duye = try! Reachability()
        duye.whenReachable = { reachability in
            let usye = WidokGry(kontroler: KontrolerGry())
//            let vuuis = UIView()
//            vuuis.addSubview(usye)
            duye.stopNotifier()
        }
        do {
            try duye.startNotifier()
        } catch {}
    
    }
}

import Network

final class Ixouex {

    static let shared = Ixouex()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.resta.RestaurantMau", qos: .background)
    private var callback: ((Bool) -> Void)?
    private var started = false

    private init() {}

    func start(_ callback: @escaping (Bool) -> Void) {
        self.callback = callback
        guard !started else { return }
        started = true

        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            DispatchQueue.main.async {
                self?.callback?(isConnected)
            }
        }

        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
        started = false
    }
}
