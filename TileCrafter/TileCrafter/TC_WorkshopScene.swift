import Combine
import CoreGraphics
import SpriteKit
import UIKit

final class TC_WorkshopScene: SKScene {

    private let store: TC_Store<TC_WorkshopFeature>
    private let timbre: TC_TimbreSpinner
    private var bag: Set<AnyCancellable> = []

    private var boardLayer = SKNode()
    private var tileLayer = SKNode()
    private var overlayLayer = SKNode()
    private var barrierLayer = SKNode()

    private var slotBackings: [[SKShapeNode]] = []
    private var tileNodes: [TC_GridCoord: SKSpriteNode] = [:]
    private var barrierNodes: [TC_GridCoord: SKNode] = [:]
    private var hoverOutline: SKShapeNode = SKShapeNode()
    private var hoverIsValid: Bool = false

    private var cellSize: CGFloat = 36
    private var boardOrigin: CGPoint = .zero
    private var lastRenderedLattice: TC_GridLattice?

    init(size: CGSize,
         store: TC_Store<TC_WorkshopFeature>,
         timbre: TC_TimbreSpinner) {
        self.store = store
        self.timbre = timbre
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .tc(TC_AtelierLore.Palette.backdropFelt)
    }

    required init?(coder aDecoder: NSCoder) { return nil }

    override func didMove(to view: SKView) {
        view.ignoresSiblingOrder = true
        addChild(boardLayer)
        addChild(tileLayer)
        addChild(barrierLayer)
        addChild(overlayLayer)
        layoutBoard()
        bindStore()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutBoard()
        renderLattice(force: true)
    }

    private func bindStore() {
        store.state
            .sink { [weak self] state in
                self?.applyState(state)
            }
            .store(in: &bag)

        store.events
            .sink { [weak self] action in
                self?.routeSideEffect(action)
            }
            .store(in: &bag)
    }

    private func applyState(_ state: TC_WorkshopState) {
        if lastRenderedLattice == nil || lastRenderedLattice != state.lattice {
            lastRenderedLattice = state.lattice
            renderLattice(force: false)
        }
        renderHover(state: state)
        renderPulses(state: state)
    }

    private func routeSideEffect(_ action: TC_WorkshopAction) {
        switch action {
        case .releaseDrag:
            timbre.spin(.place)
            TC_HapticPulse.soft.emit(enabled: store.state.value.hapticOn)
        case .finishCascade(let outcome, _):
            if !outcome.rounds.isEmpty {
                timbre.spin(.eliminate)
                if outcome.comboDepth >= TC_AtelierLore.Combo.fierceThreshold {
                    timbre.spin(.combo)
                    TC_HapticPulse.success.emit(enabled: store.state.value.hapticOn)
                } else {
                    TC_HapticPulse.crisp.emit(enabled: store.state.value.hapticOn)
                }
            }
        default:
            break
        }
    }

    private func layoutBoard() {
        boardLayer.removeAllChildren()
        slotBackings.removeAll()

        let columns = TC_AtelierLore.Grid.columns
        let rows = TC_AtelierLore.Grid.rows

        let usableWidth = size.width - TC_AtelierLore.Layout.boardSidePadding * 2
        let usableHeight = size.height - TC_AtelierLore.Layout.boardTopGutter * 2
        let measure = min(usableWidth / CGFloat(columns), usableHeight / CGFloat(rows))
        cellSize = max(8, measure)

        let boardWidth = cellSize * CGFloat(columns)
        let boardHeight = cellSize * CGFloat(rows)
        boardOrigin = CGPoint(
            x: (size.width - boardWidth) / 2,
            y: (size.height - boardHeight) / 2
        )

        let frame = SKShapeNode(rect: CGRect(x: boardOrigin.x - 6,
                                             y: boardOrigin.y - 6,
                                             width: boardWidth + 12,
                                             height: boardHeight + 12),
                                cornerRadius: TC_AtelierLore.Layout.cornerRadiusMedium)
        frame.fillColor = .tc(TC_AtelierLore.Palette.backdropWood)
        frame.strokeColor = .tc(TC_AtelierLore.Palette.gold, alpha: 0.65)
        frame.lineWidth = 2
        frame.zPosition = TC_AtelierLore.Layout.zBackdrop
        boardLayer.addChild(frame)

        var grid: [[SKShapeNode]] = []
        for r in 0..<rows {
            var rowSlots: [SKShapeNode] = []
            for c in 0..<columns {
                let rect = CGRect(x: boardOrigin.x + CGFloat(c) * cellSize + 1,
                                  y: boardOrigin.y + CGFloat(rows - 1 - r) * cellSize + 1,
                                  width: cellSize - 2,
                                  height: cellSize - 2)
                let slot = SKShapeNode(rect: rect, cornerRadius: TC_AtelierLore.Layout.cornerRadiusSmall)
                slot.fillColor = .tc(TC_AtelierLore.Palette.slotIdle, alpha: 0.16)
                slot.strokeColor = .tc(TC_AtelierLore.Palette.gold, alpha: 0.18)
                slot.lineWidth = 0.5
                slot.zPosition = TC_AtelierLore.Layout.zBoardGrid
                boardLayer.addChild(slot)
                rowSlots.append(slot)
            }
            grid.append(rowSlots)
        }
        slotBackings = grid

        hoverOutline.removeFromParent()
        hoverOutline = SKShapeNode()
        hoverOutline.zPosition = TC_AtelierLore.Layout.zDragging
        hoverOutline.isHidden = true
        overlayLayer.addChild(hoverOutline)
    }

    private func renderLattice(force: Bool) {
        let state = store.state.value
        let lattice = state.lattice

        var stillPresent: Set<TC_GridCoord> = []
        for r in 0..<lattice.rows {
            for c in 0..<lattice.columns {
                let coord = TC_GridCoord(column: c, row: r)
                guard let slot = lattice.slot(at: coord), let motif = slot.motif else { continue }
                stillPresent.insert(coord)
                if let existing = tileNodes[coord] {
                    existing.position = positionOf(coord: coord)
                    existing.alpha = slot.isFrozen ? 0.65 : 1.0
                } else {
                    let sprite = makeTileSprite(motif: motif)
                    sprite.position = positionOf(coord: coord)
                    sprite.alpha = slot.isFrozen ? 0.65 : 1.0
                    tileLayer.addChild(sprite)
                    tileNodes[coord] = sprite

                    let pop = SKAction.sequence([
                        SKAction.scale(to: 0.6, duration: 0),
                        SKAction.scale(to: 1.0, duration: 0.18)
                    ])
                    sprite.run(pop)
                }
            }
        }

        for (coord, sprite) in tileNodes where !stillPresent.contains(coord) {
            let fade = SKAction.sequence([
                SKAction.group([
                    SKAction.fadeOut(withDuration: TC_AtelierLore.Cadence.highlightLinger),
                    SKAction.scale(to: 1.25, duration: TC_AtelierLore.Cadence.highlightLinger)
                ]),
                SKAction.removeFromParent()
            ])
            sprite.run(fade)
            tileNodes.removeValue(forKey: coord)
        }

        for slotsRow in slotBackings {
            for slot in slotsRow {
                slot.fillColor = .tc(TC_AtelierLore.Palette.slotIdle, alpha: 0.10)
            }
        }

        syncBarrierNodes(lattice: lattice)
    }

    private func syncBarrierNodes(lattice: TC_GridLattice) {
        let currentCoords = Set(lattice.barriers.keys)
        let renderedCoords = Set(barrierNodes.keys)

        for coord in renderedCoords where !currentCoords.contains(coord) {
            if let node = barrierNodes[coord] {
                let shatter = SKAction.sequence([
                    SKAction.group([
                        SKAction.scale(to: 1.4, duration: 0.12),
                        SKAction.fadeOut(withDuration: 0.12)
                    ]),
                    SKAction.removeFromParent()
                ])
                node.run(shatter)
            }
            barrierNodes.removeValue(forKey: coord)
        }

        for (coord, barrier) in lattice.barriers {
            let pos = positionOf(coord: coord)
            if let existing = barrierNodes[coord] {
                existing.position = pos
                if let label = existing.children.compactMap({ $0 as? SKLabelNode }).first {
                    label.text = "\(barrier.hp)"
                }
            } else {
                let node = makeBarrierNode(hp: barrier.hp, cellSize: cellSize)
                node.position = pos
                barrierLayer.addChild(node)
                barrierNodes[coord] = node

                let appear = SKAction.sequence([
                    SKAction.scale(to: 0.5, duration: 0),
                    SKAction.scale(to: 1.0, duration: 0.22)
                ])
                node.run(appear)
            }
        }
    }

    private func makeBarrierNode(hp: Int, cellSize: CGFloat) -> SKNode {
        let container = SKNode()
        container.zPosition = TC_AtelierLore.Layout.zPlacedTile + 1

        let dimension = cellSize - 2
        let rect = CGRect(x: -dimension / 2, y: -dimension / 2, width: dimension, height: dimension)
        let bg = SKShapeNode(rect: rect, cornerRadius: TC_AtelierLore.Layout.cornerRadiusSmall)
        let stoneAlpha: CGFloat = hp >= TC_AtelierLore.Puzzle.barrierMaxHp ? 0.95 : 0.75
        bg.fillColor = .tc(TC_AtelierLore.Palette.barrierStone, alpha: stoneAlpha)
        bg.strokeColor = .tc(TC_AtelierLore.Palette.barrierCrack, alpha: 0.9)
        bg.lineWidth = max(1.5, cellSize * 0.04)
        container.addChild(bg)

        let cracks = makeCrackLines(for: hp, dimension: dimension)
        container.addChild(cracks)

        let label = SKLabelNode(text: "\(hp)")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = max(11, cellSize * 0.38)
        label.fontColor = .tc(TC_AtelierLore.Palette.parchmentWarm)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
        label.zPosition = 1
        container.addChild(label)

        return container
    }

    private func makeCrackLines(for hp: Int, dimension: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        let half = dimension / 2
        let crackCount = TC_AtelierLore.Puzzle.barrierMaxHp - hp
        if crackCount >= 1 {
            path.move(to: CGPoint(x: -half * 0.3, y: half * 0.6))
            path.addLine(to: CGPoint(x: half * 0.1, y: -half * 0.2))
        }
        if crackCount >= 2 {
            path.move(to: CGPoint(x: half * 0.4, y: half * 0.4))
            path.addLine(to: CGPoint(x: -half * 0.15, y: -half * 0.55))
        }
        let shape = SKShapeNode(path: path)
        shape.strokeColor = .tc(TC_AtelierLore.Palette.barrierCrack, alpha: 0.6)
        shape.lineWidth = max(1, dimension * 0.03)
        shape.zPosition = 0.5
        return shape
    }

    private func renderHover(state: TC_WorkshopState) {
        guard case .carrying(let blockId, _, let hover) = state.dragPhase,
              let trayIndex = state.tray.firstIndex(where: { $0.id == blockId }),
              !state.trayConsumed[trayIndex] else {
            hoverOutline.isHidden = true
            paintSlots(occupied: nil, valid: true)
            return
        }
        let block = state.tray[trayIndex]
        guard let origin = hover else {
            hoverOutline.isHidden = true
            paintSlots(occupied: nil, valid: true)
            return
        }

        let footprint = block.footprint(origin: origin)
        let valid = state.lattice.canHost(block, at: origin)
        hoverIsValid = valid

        let path = CGMutablePath()
        for foot in footprint where state.lattice.contains(foot) {
            let pos = positionOf(coord: foot)
            let rect = CGRect(x: pos.x - cellSize / 2 + 2,
                              y: pos.y - cellSize / 2 + 2,
                              width: cellSize - 4,
                              height: cellSize - 4)
            path.addRoundedRect(in: rect,
                                cornerWidth: TC_AtelierLore.Layout.cornerRadiusSmall,
                                cornerHeight: TC_AtelierLore.Layout.cornerRadiusSmall)
        }
        hoverOutline.path = path
        hoverOutline.fillColor = valid ?
            .tc(TC_AtelierLore.Palette.slotInviting, alpha: 0.42) :
            .tc(TC_AtelierLore.Palette.slotForbidden, alpha: 0.38)
        hoverOutline.strokeColor = valid ?
            .tc(TC_AtelierLore.Palette.gold, alpha: 0.9) :
            .tc(TC_AtelierLore.Palette.lacquerRed, alpha: 0.85)
        hoverOutline.lineWidth = 2
        hoverOutline.isHidden = false
        paintSlots(occupied: Set(footprint), valid: valid)
    }

    private func paintSlots(occupied: Set<TC_GridCoord>?, valid: Bool) {
        let lattice = store.state.value.lattice
        for r in 0..<lattice.rows {
            for c in 0..<lattice.columns {
                guard r < slotBackings.count, c < slotBackings[r].count else { continue }
                let coord = TC_GridCoord(column: c, row: r)
                let target = slotBackings[r][c]
                if let occupied = occupied, occupied.contains(coord) {
                    target.fillColor = valid ?
                        .tc(TC_AtelierLore.Palette.slotInviting, alpha: 0.30) :
                        .tc(TC_AtelierLore.Palette.slotForbidden, alpha: 0.28)
                } else {
                    target.fillColor = .tc(TC_AtelierLore.Palette.slotIdle, alpha: 0.10)
                }
            }
        }
    }

    private func renderPulses(state: TC_WorkshopState) {
        guard !state.pendingPulses.isEmpty else { return }
        for pulse in state.pendingPulses {
            let pos = positionOf(coord: pulse.coord)
            let label = SKLabelNode(text: pulse.pattern.headline)
            label.fontName = "AvenirNext-Heavy"
            label.fontSize = max(13, cellSize * 0.42)
            label.fontColor = .tc(TC_AtelierLore.Palette.gold)
            label.position = CGPoint(x: pos.x, y: pos.y + cellSize * 0.55)
            label.zPosition = TC_AtelierLore.Layout.zDragging
            overlayLayer.addChild(label)

            let lift = SKAction.moveBy(x: 0, y: cellSize * 0.9, duration: 0.6)
            let fade = SKAction.fadeOut(withDuration: 0.6)
            label.run(SKAction.sequence([
                SKAction.group([lift, fade]),
                SKAction.removeFromParent()
            ]))
        }
        DispatchQueue.main.async { [weak self] in
            self?.store.dispatch(.clearPulses)
        }
    }

    private func makeTileSprite(motif: TC_TileMotif) -> SKSpriteNode {
        let texture = SKTexture(imageNamed: motif.assetName)
        let dimension = cellSize - 2
        let sprite = SKSpriteNode(texture: texture)
        sprite.size = CGSize(width: dimension, height: dimension)
        sprite.zPosition = TC_AtelierLore.Layout.zPlacedTile
        sprite.color = .tc(TC_AtelierLore.Palette.parchmentWarm)
        sprite.colorBlendFactor = 0
        return sprite
    }

    private func positionOf(coord: TC_GridCoord) -> CGPoint {
        let lattice = store.state.value.lattice
        let xCenter = boardOrigin.x + CGFloat(coord.column) * cellSize + cellSize / 2
        let yCenter = boardOrigin.y + CGFloat(lattice.rows - 1 - coord.row) * cellSize + cellSize / 2
        return CGPoint(x: xCenter, y: yCenter)
    }

    func coord(at scenePoint: CGPoint) -> TC_GridCoord? {
        let lattice = store.state.value.lattice
        let columnRaw = (scenePoint.x - boardOrigin.x) / cellSize
        let rowFromBottom = (scenePoint.y - boardOrigin.y) / cellSize
        let column = Int(floor(columnRaw))
        let row = lattice.rows - 1 - Int(floor(rowFromBottom))
        let coord = TC_GridCoord(column: column, row: row)
        return lattice.contains(coord) ? coord : nil
    }

    var boardCellSize: CGFloat { cellSize }
    var boardAnchor: CGPoint { boardOrigin }
}
