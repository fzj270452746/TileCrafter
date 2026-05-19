import Combine
import SpriteKit
import SwiftUI
import UIKit

struct TC_WorkshopStage: View {

    let mode: TC_GameMode
    var onExit: () -> Void = {}

    @Environment(\.timbreSpinner) private var timbre
    @Environment(\.relicVault) private var vault

    @StateObject private var orchestrator: TC_WorkshopOrchestrator

    @State private var sceneRef: TC_WorkshopScene?
    @State private var sceneSize: CGSize = .zero
    @State private var showPause: Bool = false

    init(mode: TC_GameMode, onExit: @escaping () -> Void = {}) {
        self.mode = mode
        self.onExit = onExit
        _orchestrator = StateObject(wrappedValue: TC_WorkshopOrchestrator(mode: mode))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Color.tc(TC_AtelierLore.Palette.backdropWood).ignoresSafeArea()

                VStack(spacing: 0) {
                    TC_HudFrieze(
                        score: orchestrator.viewState.score,
                        best: orchestrator.viewState.bestScore,
                        comboDepth: orchestrator.viewState.comboDepth,
                        hazardLevel: orchestrator.viewState.hazardLevel,
                        clockRemaining: orchestrator.viewState.clockRemaining,
                        mode: mode,
                        barrierCount: orchestrator.viewState.lattice.barriers.count,
                        onPause: { showPause = true; orchestrator.dispatch(.requestPause) },
                        onExit: onExit
                    )
                    .padding(.horizontal, 18)
                    .padding(.top, 6)

                    sceneView(boardSize: boardSize(in: geo))
                        .frame(width: boardSize(in: geo).width,
                               height: boardSize(in: geo).height)
                        .padding(.top, TC_AtelierLore.Layout.boardTopGutter)

                    Spacer(minLength: 0)

                    TC_TraySatchel(
                        blocks: orchestrator.viewState.tray,
                        consumed: orchestrator.viewState.trayConsumed,
                        carryingId: carryingBlockId,
                        onPickUp: handlePickUp,
                        onDragChanged: handleDragChanged(blockId:fingerInWindow:),
                        onDragEnded: handleDragEnded(blockId:fingerInWindow:)
                    )
                    .padding(.horizontal, TC_AtelierLore.Layout.traySidePadding)
                    .padding(.bottom, 24)
                }

                if showPause {
                    TC_VerdictParchment(
                        kind: .confirm,
                        headline: "Paused",
                        message: "Take a breath. The atelier awaits.",
                        primaryTitle: "Resume",
                        secondaryTitle: "Quit",
                        onPrimary: {
                            showPause = false
                            orchestrator.dispatch(.resume)
                        },
                        onSecondary: {
                            showPause = false
                            onExit()
                        }
                    )
                }

                if isVerdictDefeat {
                    TC_VerdictParchment(
                        kind: .defeat,
                        headline: "Atelier Sealed",
                        message: orchestrator.viewState.lastVerdictHeadline.isEmpty
                            ? "No room left to craft."
                            : orchestrator.viewState.lastVerdictHeadline,
                        primaryTitle: "Craft Again",
                        secondaryTitle: "Home",
                        onPrimary: {
                            orchestrator.dispatch(.requestRestart)
                        },
                        onSecondary: onExit
                    )
                }

                if isVerdictTriumph {
                    let isPuzzle = mode == .puzzle
                    TC_VerdictParchment(
                        kind: .victory,
                        headline: isPuzzle ? "Barriers Cleared!" : "Bell Rings",
                        message: orchestrator.viewState.lastVerdictHeadline,
                        primaryTitle: isPuzzle ? "Next Round" : "Another Round",
                        secondaryTitle: "Home",
                        onPrimary: {
                            if isPuzzle {
                                orchestrator.dispatch(.advancePuzzleRound)
                            } else {
                                orchestrator.dispatch(.requestRestart)
                            }
                        },
                        onSecondary: onExit
                    )
                }
            }
            .onAppear {
                let best = vault.loadBest(for: mode)
                let sfx = vault.loadSfxOn()
                let haptic = vault.loadHapticOn()
                timbre.updatePreferences(sfxOn: sfx, bgmOn: vault.loadBgmOn())
                orchestrator.attachTimbre(timbre)
                orchestrator.attachVault(vault)
                orchestrator.start(savedBest: best, sfxOn: sfx, hapticOn: haptic)
            }
            .onDisappear { orchestrator.stop() }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
    }

    private var isVerdictDefeat: Bool {
        orchestrator.viewState.lifecycle == .verdictDefeat
    }
    private var isVerdictTriumph: Bool {
        orchestrator.viewState.lifecycle == .verdictTriumph
    }

    private var carryingBlockId: UUID? {
        if case .carrying(let id, _, _) = orchestrator.viewState.dragPhase { return id }
        return nil
    }

    private func boardSize(in geo: GeometryProxy) -> CGSize {
        let columns = CGFloat(TC_AtelierLore.Grid.columns)
        let rows = CGFloat(TC_AtelierLore.Grid.rows)
        let usableWidth = geo.size.width - TC_AtelierLore.Layout.boardSidePadding * 2
        let usableHeight = geo.size.height
            - TC_AtelierLore.Layout.hudHeight
            - geo.size.height * TC_AtelierLore.Layout.trayHeightRatio
            - 60
        let cell = min(usableWidth / columns, usableHeight / rows)
        let safe = max(cell, 20)
        return CGSize(width: safe * columns, height: safe * rows)
    }

    @ViewBuilder
    private func sceneView(boardSize: CGSize) -> some View {
        TC_SpriteHost(orchestrator: orchestrator,
                      preferredSize: boardSize,
                      onSceneReady: { scene, size in
                          self.sceneRef = scene
                          self.sceneSize = size
                      })
    }

    private func handlePickUp(blockId: UUID, fingerInWindow: CGPoint) {
        guard let scene = sceneRef else { return }
        let scenePoint = scene.convertPoint(fromView: hostPoint(fingerInWindow))
        orchestrator.dispatch(.beginDrag(blockId: blockId, fingerPoint: scenePoint))
        let hover = scene.coord(at: scenePoint)
        orchestrator.dispatch(.dragMoved(fingerPoint: scenePoint, hover: hover))
    }

    private func handleDragChanged(blockId: UUID, fingerInWindow: CGPoint) {
        guard let scene = sceneRef else { return }
        let scenePoint = scene.convertPoint(fromView: hostPoint(fingerInWindow))
        let hover = scene.coord(at: scenePoint)
        orchestrator.dispatch(.dragMoved(fingerPoint: scenePoint, hover: hover))
    }

    private func handleDragEnded(blockId: UUID, fingerInWindow: CGPoint) {
        guard let scene = sceneRef else { return }
        let scenePoint = scene.convertPoint(fromView: hostPoint(fingerInWindow))
        let coord = scene.coord(at: scenePoint)
        orchestrator.dispatch(.releaseDrag(at: coord))
    }

    private func hostPoint(_ windowPoint: CGPoint) -> CGPoint {
        guard let scene = sceneRef, let view = scene.view else { return windowPoint }
        let viewFrame = view.convert(view.bounds, to: nil)
        return CGPoint(x: windowPoint.x - viewFrame.minX,
                       y: windowPoint.y - viewFrame.minY)
    }
}

final class TC_WorkshopOrchestrator: ObservableObject {

    let store: TC_Store<TC_WorkshopFeature>
    @Published var viewState: TC_WorkshopState

    private var bag: Set<AnyCancellable> = []
    private var heartbeat: Timer?
    private weak var timbre: TC_TimbreSpinner?
    private var vault: TC_RelicVault?

    let mode: TC_GameMode

    init(mode: TC_GameMode) {
        self.mode = mode
        let initial = TC_WorkshopFeature.makeInitial(mode: mode)
        self.viewState = initial
        self.store = TC_Store(initial: initial)
        store.state
            .sink { [weak self] state in self?.viewState = state }
            .store(in: &bag)

        store.events
            .sink { [weak self] action in self?.persistIfNeeded(action) }
            .store(in: &bag)
    }

    func attachTimbre(_ spinner: TC_TimbreSpinner) { self.timbre = spinner }
    func attachVault(_ vault: TC_RelicVault) { self.vault = vault }

    func dispatch(_ action: TC_WorkshopAction) { store.dispatch(action) }

    func start(savedBest: Int, sfxOn: Bool, hapticOn: Bool) {
        dispatch(.onAppear(mode: mode, savedBest: savedBest, sfxOn: sfxOn, hapticOn: hapticOn))
        startHeartbeat()
    }

    func stop() {
        heartbeat?.invalidate()
        heartbeat = nil
        if let vault = vault {
            vault.appendTotals(chains: viewState.totalChains,
                               cascades: viewState.totalCascades)
        }
    }

    private func startHeartbeat() {
        heartbeat?.invalidate()
        heartbeat = Timer.scheduledTimer(
            withTimeInterval: TC_AtelierLore.Cadence.frameInterval,
            repeats: true
        ) { [weak self] _ in
            self?.tickClock()
        }
        if let timer = heartbeat { RunLoop.main.add(timer, forMode: .common) }
    }

    private func tickClock() {
        let elapsed = TC_AtelierLore.Cadence.frameInterval
        store.dispatch(.timerTick(delta: elapsed))
    }

    private func persistIfNeeded(_ action: TC_WorkshopAction) {
        guard case .persistBest(let score) = action else { return }
        vault?.saveBest(score, for: mode)
    }
}

struct TC_SpriteHost: UIViewRepresentable {

    let orchestrator: TC_WorkshopOrchestrator
    let preferredSize: CGSize
    var onSceneReady: (TC_WorkshopScene, CGSize) -> Void

    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: CGRect(origin: .zero, size: preferredSize))
        view.backgroundColor = .clear
        view.allowsTransparency = true
        view.ignoresSiblingOrder = true
        view.isMultipleTouchEnabled = false

        let scene = TC_WorkshopScene(
            size: preferredSize,
            store: orchestrator.store,
            timbre: TC_TimbreSpinner.fallback
        )
        scene.scaleMode = .resizeFill
        view.presentScene(scene)
        DispatchQueue.main.async {
            onSceneReady(scene, preferredSize)
        }
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        guard let scene = view.scene as? TC_WorkshopScene else { return }
        if scene.size != preferredSize {
            scene.size = preferredSize
        }
    }
}

extension TC_TimbreSpinner {
    static let fallback = TC_TimbreSpinner()
}
