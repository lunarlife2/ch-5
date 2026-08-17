//
//  EditViewModel.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import Foundation
import SwiftUI
import RealityKit
import SwiftData
import simd


enum JewelryEditorMode: String, CaseIterable, Identifiable {
    case band
    case handMannequin

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .band:
            return "Ring View"
        case .handMannequin:
            return "Hand View"
        }
    }

    var image: String {
        switch self {
        case .band:
            return "ring_view"
        case .handMannequin:
            return "hand.raised"
        }
    }

    var isSystemImage: Bool {
        switch self {
        case .band:
            return false
        case .handMannequin:
            return true
        }
    }
}

@Observable
final class EditViewModel {

    let scene = JewelrySceneController()
    private let persistence = DesignPersistenceService()
    private(set) var designFile: DesignFile
    private var modelContext: ModelContext?

    var mode: JewelryEditorMode = .band {
        didSet { scene.updateVisibility(for: mode) }
    }

    private(set) var hasUnsavedChanges = false
    private(set) var selectedGemName: String?
    private(set) var pendingDeleteGemName: String?
    var liveDragGlobalPoint: CGPoint?
    private(set) var editorFrameInGlobal: CGRect = .zero
    private(set) var trashFrameInGlobal: CGRect = .zero
    private var pendingBandAssetPath: String = "Flat_Band_Ring"
    private var pendingBandName: String = "plain band usd"

    private let snapScreenRadius: CGFloat = 50
    private let tapAlignRadius: Float = 0.0025

    var design: Design? {
        designFile.design
    }

    init(designFile: DesignFile) {
        self.designFile = designFile
    }

    func setDesignFile(_ file: DesignFile) {
        self.designFile = file
    }
    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }
    func setRealityContent(_ content: RealityViewCameraContent) {
        scene.setRealityContent(content)
    }

    func setEditorFrame(_ frame: CGRect) {
        editorFrameInGlobal = frame
        scene.setEditorFrame(frame)
    }
    func isInsideEditor(_ globalPoint: CGPoint) -> Bool {
        editorFrameInGlobal.contains(globalPoint)
    }
    func setTrashFrame(_ frame: CGRect) {
        trashFrameInGlobal = frame
    }
    func isOverTrash(_ globalPoint: CGPoint) -> Bool {
        trashFrameInGlobal.contains(globalPoint)
    }
    func markDirty() {
        hasUnsavedChanges = true
    }
    func clearDirty() {
        hasUnsavedChanges = false
    }
    func selectGem(_ gem: Entity) {
        selectedGemName = gem.name
    }
    func clearSelection() {
        selectedGemName = nil
    }
    func requestDelete(for gem: Entity) {
        selectedGemName = gem.name
        pendingDeleteGemName = gem.name
    }
    func cancelPendingDelete() {
        pendingDeleteGemName = nil
    }
    func confirmPendingDelete() {
        guard let name = pendingDeleteGemName else { return }
        selectedGemName = name
        delete()
        pendingDeleteGemName = nil
    }

    func loadScene() async {
        await scene.setup(mode: mode, savedGems: design?.gems ?? [], savedBand: design?.band)
    }

    func handleDrop(identifier: String, screenLocation: CGPoint? = nil, containerSize: CGSize? = nil) async {
        switch identifier {
        case "Flat_Band_Ring":
            await scene.replaceBand(saved: design?.band)
            markDirty()
        case "Gemstone":
            if let gem = await scene.addStone(screenLocation: screenLocation, containerSize: containerSize) {
                selectGem(gem)
            }
            markDirty()
        default:
            print("Unknown drop identifier:", identifier)
        }
    }

    func selectAndAlign(_ gem: Entity) {
        selectedGemName = gem.name

        let allSnapPoints = scene.band.children.first?.children.filter {
            $0.components[SnapPointComponent.self] != nil
        } ?? []

        if let target = SnappingService.nearestSnapPoint(
            to: gem,
            among: allSnapPoints,
            maxDistance: tapAlignRadius,
            allowOccupiedBySelf: gem.name
        ) {
            SnappingService.attach(gem: gem, to: target)
            markDirty()
        }
    }

    func prepareGemForDragging(_ gem: Entity) {
        selectedGemName = gem.name

        if SnappingService.isAttached(gem) {
            SnappingService.detach(gem: gem, backTo: scene.gemAnchor)
        }

        var state = gem.gestureStateComponent
        state.lastPositionDrag = gem.position(relativeTo: nil)
        gem.gestureStateComponent = state

        markDirty()
    }

    func sceneTransformTarget() -> Entity {
        if let selectedGemName,
           let gem = scene.allGemEntities().first(where: { $0.name == selectedGemName }) {
            return gem
        }

        switch mode {
        case .band:
            return scene.bandPivot
        case .handMannequin:
            return scene.mannequinPivot
        }
    }

    func reapplyAttachedGemScales() {
        guard let bandEntity = scene.bandAnchor.children.first else { return }

        let snapPoints = bandEntity.children.filter {
            $0.components[SnapPointComponent.self] != nil
        }

        for snap in snapPoints {
            for child in snap.children {
                SnappingService.reapplyFixedScale(for: child)
            }
        }
    }

    func delete() {
        guard let name = selectedGemName,
              let gem = scene.allGemEntities().first(where: { $0.name == name })
        else { return }

        if gem.components[AttachmentComponent.self]?.attachedSnapID != nil {
            SnappingService.detach(gem: gem, backTo: scene.gemAnchor)
        }
        gem.removeFromParent()

        if let design = designFile.design, let modelContext {
            persistence.delete(gemName: name, from: design, modelContext: modelContext)
        }

        selectedGemName = nil
        hasUnsavedChanges = true
    }

    func save(ringSizeID: Int?, ringSizeSystem: RingSizeSystem?) {
        guard let modelContext, let design = designFile.design else { return }
        do {
            try persistence.save(
                gemEntities: scene.allGemEntities(),
                bandEntity: scene.bandAnchor.children.first,
                bandPivot: scene.bandPivot,
                pendingBandAssetPath: pendingBandAssetPath,
                pendingBandName: pendingBandName,
                ringSizeID: ringSizeID,
                ringSizeSystem: ringSizeSystem,
                designFile: designFile,
                design: design,
                modelContext: modelContext
            )
            hasUnsavedChanges = false
        } catch {
            print("save failed: \(error)")
        }
    }
}
