//
//  JewelrySceneController.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 17/08/26.
//

import Foundation
import SwiftUI
import RealityKit
import simd

@Observable
final class JewelrySceneController {
    
    let gizmoController = GizmoController()
    let cameraController = CameraController()
    
    let rootEntity = Entity()
    
    let bandPivot = Entity()
    let bandAnchor = Entity()
    
    var band: Entity {
        bandAnchor
    }
    
    let gemAnchor = Entity()
    
    var selectedGem: Entity {
        gemAnchor
    }
    
    let mannequinAnchor = Entity()
    let mannequinPivot = Entity()
    
    var mannequin: Entity {
        mannequinAnchor
    }
    
    var bandOrientation: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
    private var rotateBandStartOrientation: simd_quatf?
    private var rotateGemAnchorStartOrientation: simd_quatf?
    
    private let targetBandDiameter: Float = 0.3
    private let targetGemstoneDiameter: Float = 0.1
    private let targetMannequinDiameter: Float = 0.004
    private let gemFrontDepth: Float = 0.01
    private let gemFixedTapPosition = SIMD3<Float>(0.2, 0, 0.001)
    
    private(set) var editorFrameInGlobal: CGRect = .zero
    private(set) var realityContent: RealityViewCameraContent?
    private var isSetup = false
    
    func setEditorFrame(_ frame: CGRect) { editorFrameInGlobal = frame }
    func setRealityContent(_ content: RealityViewCameraContent) { realityContent = content }
    func isInsideEditorFrame(_ globalPoint: CGPoint) -> Bool { editorFrameInGlobal.contains(globalPoint) }
    
    func setup(bandURL: URL?, bandSource: BandSourceComponent, gemURLs: [String: URL], mode: JewelryEditorMode, savedGems: [GemComponent], savedBand: BandComponent?) async {
        guard !isSetup else { return }
        isSetup = true
        
        bandPivot.addChild(bandAnchor)
        rootEntity.addChild(bandPivot)
        mannequinPivot.addChild(mannequinAnchor)
        
        rootEntity.addChild(cameraController.pivot)
        rootEntity.addChild(mannequinPivot)
        rootEntity.addChild(gemAnchor)
        
        gizmoController.install(
            in: rootEntity
        )
        
        bandPivot.components.set(
            GestureComponent(
                typeJewelry: .band,
                canDrag: false,
                canScale: true,
                canRotate: true
            )
        )
        
        mannequinPivot.components.set(
            GestureComponent(
                typeJewelry: .handMannequin,
                canDrag: false,
                canScale: true,
                canRotate: true
            )
        )
                
        if let bandURL {
            await loadBand(from: bandURL, source: bandSource, saved: savedBand)
        } else {
            await loadBundledBand(named: bandSource.assetStoragePath, saved: savedBand)
        }
        await loadMannequin()
        await loadSavedGems(gems: savedGems, urls: gemURLs)
        updateVisibility(for: mode)
    }
    
    func beginRotateBand() {
        rotateBandStartOrientation = bandAnchor.orientation(relativeTo: nil)
        rotateGemAnchorStartOrientation = gemAnchor.orientation(relativeTo: nil)
    }
    
    func rotateBand(deltaX: Float, deltaY: Float) {
        guard let startOrientation = rotateBandStartOrientation else {
            rotateBandStartOrientation = bandAnchor.orientation(relativeTo: nil)
            rotateGemAnchorStartOrientation = gemAnchor.orientation(relativeTo: nil)
            return
        }
        
        let rotationY = deltaX * 0.01
        let rotationX = deltaY * 0.01
        
        let qY = simd_quatf(angle: rotationY, axis: SIMD3<Float>(0, 1, 0))
        let qX = simd_quatf(angle: rotationX, axis: SIMD3<Float>(1, 0, 0))
        let delta = qY * qX
        
        bandAnchor.orientation = delta * startOrientation
        bandOrientation = bandAnchor.orientation(relativeTo: nil)
        
        if let gemStart = rotateGemAnchorStartOrientation {
            gemAnchor.orientation = delta * gemStart
        }
        
        gizmoController.updateGizmoTransform()
        
//        ensureBandGroupVisible()
    }
    
    func snapBand(to targetOrientation: simd_quatf) {
        bandAnchor.orientation = targetOrientation
        gemAnchor.orientation = targetOrientation
        bandOrientation = bandAnchor.orientation(relativeTo: nil)
        gizmoController.updateGizmoTransform()
    }
    
    func endRotateBand() {
        rotateBandStartOrientation = nil
        rotateGemAnchorStartOrientation = nil
    }
    
    
    func orbitCamera(deltaX: Float, deltaY: Float) {
        cameraController.orbit(
            deltaX: deltaX,
            deltaY: deltaY
        )
    }
    
    func rotateSelectedEntity(deltaX: Float, deltaY: Float) {
        guard let entity = gizmoController.selectedEntity else {
            return
        }
        let rotationY = deltaX * 0.01
        let rotationX = deltaY * 0.01
        
        let qY = simd_quatf(angle: rotationY, axis: SIMD3<Float>(0, 1, 0))
        let qX = simd_quatf(angle: rotationX, axis: SIMD3<Float>(1, 0, 0))
        
        entity.orientation = qY * qX * entity.orientation
        gizmoController.updateGizmoTransform()
    }
    
    func selectViewAxis(_ axis: ViewAxis) {
        cameraController.setView(axis: axis)
    }
    
    func selectEntity(at screenLocation: CGPoint) {
        guard let entity = entityAtScreenLocation(screenLocation) else {
            gizmoController.deselect()
            setSnapPointVisualsVisible(false)
            return
        }
        
        gizmoController.select(entity)
        
        if entity.components[GestureComponent].self?.typeJewelry == .gemstone {
            setSnapPointVisualsVisible(true)
        } else {
            setSnapPointVisualsVisible(false)
        }
    }
    
    func deselectEntity() {
        gizmoController.deselect()
    }
    
    func updateVisibility(for mode: JewelryEditorMode) {
        bandPivot.isEnabled = mode == .band
        mannequinPivot.isEnabled = mode == .handMannequin
    }
    
    func loadBand(from localURL: URL, source: BandSourceComponent, saved: BandComponent? = nil) async {
        do {
            let band = try await ModelEntity(contentsOf: localURL)
            band.components.set(source)
            prepareAndInstall(band: band, saved: saved)
        } catch {
            print("Failed to load band from URL: ", error)
        }
    }
    
    func loadBundledBand(named name: String, saved: BandComponent? = nil) async {
        do {
            let band = try await Entity(named: name)
            band.components.set(
                BandSourceComponent(libraryAssetID: UUID(), assetStoragePath: "Flat_Band_Ring", name: "plain band usd")
            )
            prepareAndInstall(band: band, saved: saved)
        } catch {
            print("Failed to load bundled band entity: ", error)
        }
    }
    
    func replaceBand(from localURL: URL, source: BandSourceComponent, saved: BandComponent? = nil) async {
        await loadBand(from: localURL, source: source, saved: saved)
    }
    
    
    private func prepareAndInstall(band: Entity, saved: BandComponent?) {
        let size = band.visualBounds(relativeTo: band).extents

        let rawDiameter = max(size.x, size.z)

        guard rawDiameter > 0 else {
            return
        }

        let scale = targetBandDiameter / rawDiameter

        band.scale = .init(repeating: scale)
        band.position = [-0.001, 0, 0]

        band.generateCollisionShapes(recursive: true)

        band.components.set(InputTargetComponent())

        band.components.set(
            GestureComponent(
                typeJewelry: .band,
                canDrag: false,
                canScale: true,
                canRotate: true
            )
        )

        SnappingService.addSnapPoints(to: band)

        bandAnchor.orientation = simd_quatf(
            angle: 0,
            axis: SIMD3<Float>(0, 1, 0)
        )

        if let saved {
            if let orientation = saved.orientation {
                bandAnchor.orientation = orientation
            }

            if let scale = saved.scaleFactor {
                band.scale = .init(repeating: Float(scale))
            }
        }

        bandAnchor.children.removeAll()
        bandAnchor.addChild(band)

        bandOrientation = bandAnchor.orientation(relativeTo: nil)

        gizmoController.updateGizmoTransform()
    }
    
    func loadMannequin() async {
        do {
            let mannequin = try await Entity(named: "Simplified_Hand_For_Artists")
            
            let mannequinSize = mannequin.visualBounds(relativeTo: nil).extents
            mannequin.scale = .init(repeating: targetMannequinDiameter / max(mannequinSize.x, mannequinSize.y))
            mannequin.position = [0, -0.3, 0]
            
            mannequin.generateCollisionShapes(recursive: true, static: true)
            mannequin.components.set(InputTargetComponent())
            mannequin.components.set(
                GestureComponent(
                    typeJewelry: .handMannequin,
                    canDrag: false,
                    canScale: true,
                    canRotate: true
                )
            )
            mannequinAnchor.addChild(mannequin)
            gizmoController.updateGizmoTransform()
        } catch {
            print("Failed to load entity", error)
        }
    }
    
    func addStone(from localURL: URL, source: Gem, screenLocation: CGPoint? = nil, containerSize: CGSize? = nil) async -> Entity? {
        do {
            let gemstone = try await ModelEntity(
                contentsOf: localURL
            )
            
            guard let model = gemstone.components[ModelComponent.self] else {
                return nil
            }
            
            gemstone.transform = Transform.identity
            let localBounds = model.mesh.bounds
            let extents = localBounds.extents

            let maxDimension = max(extents.x, extents.y, extents.z)
            guard maxDimension > 0, maxDimension.isFinite else {
                return nil
            }

            let initialScale = targetGemstoneDiameter / maxDimension
            
            guard initialScale.isFinite, initialScale > 0 else {
                return nil
            }

            gemstone.scale = .init(repeating: initialScale)

            gemstone.components.set(AttachmentComponent(targetWorldScale: initialScale))

            gemstone.components.set(GemSourceComponent(libraryAssetID: source.id, assetStoragePath: source.assetId.storagePath, cut: source.gemShape, color: source.gemMaterial))

            gemstone.name = UUID().uuidString

            gemstone.position = spawnPosition(screenLocation: screenLocation, containerSize: containerSize)

            gemstone.generateCollisionShapes(recursive: true)

            gemstone.components.set(InputTargetComponent())

            gemstone.components.set(GestureComponent(typeJewelry: .gemstone, canDrag: true, canScale: false, canRotate: false))

            gemAnchor.addChild(gemstone)

            let finalBounds = gemstone.visualBounds(
                relativeTo: nil
            )
            return gemstone

        } catch {
            print(error)
            return nil
        }
    }
    
    func loadSavedGems(gems: [GemComponent], urls: [String: URL]) async {
        for component in gems {
            guard let localURL = urls[component.name] else {
                print("Missing URL: ", component.name)
                continue
            }
            
            do {
                let entity = try await ModelEntity(contentsOf: localURL)
                entity.name = component.name
                
                let gemstoneSize = entity.visualBounds(relativeTo: nil).extents
                let defaultScale = targetGemstoneDiameter / max(gemstoneSize.x, gemstoneSize.y)
                let targetWorldScale = Float(component.scaleFactor ?? Double(defaultScale))
                
                entity.components.set(AttachmentComponent(targetWorldScale: targetWorldScale))
                entity.scale = .init(repeating: targetWorldScale) // sementara, sebelum attach/parent
                
                entity.generateCollisionShapes(recursive: true)
                entity.components.set(InputTargetComponent())
                entity.components.set(
                    GestureComponent(typeJewelry: .gemstone, canDrag: true, canScale: false, canRotate: true)
                )
                
                if let snapID = component.attachedSnapPointID, let snapPoint = findSnapPoint(id: snapID) {
                    SnappingService.attach(gem: entity, to: snapPoint)

                    if let orientation = component.orientation {
                        entity.setOrientation(orientation, relativeTo: nil)
                    }

                    print("[LOAD GEM]", entity.name, "attached to", snapID)
                } else {
                    if let pos = component.position {
                        entity.position = pos
                    }
                    if let orientation = component.orientation {
                        entity.orientation = orientation
                    }
                    gemAnchor.addChild(entity)
                }
            } catch {
                print("Failed to load", component.name, error)
            }
            
        }
    }
    
    func allGemEntities() -> [Entity] {
        var result: [Entity] = []
        result.append(contentsOf: gemAnchor.children)
        
        guard let bandEntity = bandAnchor.children.first else {
            return result
        }
        let snapPoints = bandEntity.children.filter { $0.components[SnapPointComponent.self] != nil }
        
        for snap in snapPoints {
            for child in snap.children {
                if child.components[GestureComponent.self]?.typeJewelry == .gemstone {
                    result.append(child)
                }
            }
        }
        return result
    }
    
    func entityAtScreenLocation(_ location: CGPoint) -> Entity? {
        guard let realityContent else { return nil }
        guard let hitEntity = realityContent.entity(at: location, in: .local) else { return nil }
        return hitEntity.gestureTarget()
    }
    
    func localPoint(fromGlobal point: CGPoint) -> CGPoint {
        CGPoint(x: point.x - editorFrameInGlobal.minX, y: point.y - editorFrameInGlobal.minY)
    }
    
    private func findSnapPoint(id: String) -> Entity? {
        var result: Entity?
        
        func search(_ entity: Entity) {
            if let snap = entity.components[SnapPointComponent.self], snap.snapID == id {
                result = entity
                return
            }
            for child in entity.children {
                search(child)
                if result != nil { return }
            }
        }
        
        search(rootEntity)
        return result
    }
    
    private func spawnPosition(screenLocation: CGPoint?, containerSize: CGSize?) -> SIMD3<Float> {
        guard let loc = screenLocation, let size = containerSize, size.width > 0, size.height > 0 else {
            return gemFixedTapPosition
        }
        
        let normalizedX = Float(loc.x / size.width) - 0.5
        
        let normalizedY = Float(loc.y / size.height) - 0.5
        
        return SIMD3<Float>(normalizedX * 0.004, -normalizedY * 0.004, gemFrontDepth)
    }
    
    func allSnapPoints() -> [Entity] {
        guard let bandEntity = bandAnchor.children.first else {
            return []
        }
        
        return bandEntity.children.filter {
            $0.components[SnapPointComponent.self] != nil
        }
    }
    
    func screenAnchorPoints(for entity: Entity, buttonSpacing: CGFloat = 70) -> (left: CGPoint, right: CGPoint, center: CGPoint)? {
        guard let realityContent else { return nil }

        let bounds = entity.visualBounds(relativeTo: nil)

        let corners = [
            SIMD3<Float>(bounds.min.x, bounds.min.y, bounds.min.z),
            SIMD3<Float>(bounds.max.x, bounds.min.y, bounds.min.z),
            SIMD3<Float>(bounds.min.x, bounds.max.y, bounds.min.z),
            SIMD3<Float>(bounds.max.x, bounds.max.y, bounds.min.z),
            SIMD3<Float>(bounds.min.x, bounds.min.y, bounds.max.z),
            SIMD3<Float>(bounds.max.x, bounds.min.y, bounds.max.z),
            SIMD3<Float>(bounds.min.x, bounds.max.y, bounds.max.z),
            SIMD3<Float>(bounds.max.x, bounds.max.y, bounds.max.z)
        ]

        let projected = corners.compactMap {
            realityContent.project(point: $0, to: .local)
        }

        guard !projected.isEmpty else {
            return nil
        }

        let minX = projected.map(\.x).min()!
        let maxX = projected.map(\.x).max()!

        let centerX = (minX + maxX) / 2

        let midY = projected.map(\.y).reduce(0, +) / CGFloat(projected.count)

        return (
            left: CGPoint(x: centerX - buttonSpacing, y: midY),
            right: CGPoint(x: centerX + buttonSpacing, y: midY),
            center: CGPoint(x: centerX, y: midY)
        )
    }

    func rotateSelectedGemAroundViewAxis(byDegrees delta: Float) {
        guard let entity = gizmoController.selectedEntity, entity.components[GestureComponent.self]?.typeJewelry == .gemstone else {
            return
        }
        let rotation = simd_quatf(angle: delta * .pi / 180, axis: SIMD3<Float>(0, 1, 0))
        let currentWorldOrientation = entity.orientation(relativeTo: nil)
        entity.setOrientation(rotation * currentWorldOrientation, relativeTo: nil)
        gizmoController.updateGizmoTransform()
    }
    
    func setSnapPointVisualsVisible(_ visible: Bool, excludingOccupied: Bool = true) {
        for snap in allSnapPoints() {
            guard let visual = snap.children.first(where: { $0.name == "snap-visual" }) else {
                continue
            }

            if excludingOccupied,
               let component = snap.components[SnapPointComponent.self],
               component.occupiedByGemName != nil {
                visual.isEnabled = false
                continue
            }

            visual.isEnabled = visible
        }
    }
}
