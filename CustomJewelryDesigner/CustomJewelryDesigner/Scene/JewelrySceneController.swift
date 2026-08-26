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

private struct PendingGemAttach {
    let entity: Entity
    let snapID: String
}

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
    
    let mannequinAnchorLeft = Entity()
    let mannequinAnchorRight = Entity()

    let mannequinPivot = Entity()
    
    var mannequin: Entity {
        activeHand == .left ? mannequinAnchorLeft : mannequinAnchorRight
    }
    
    private var activeHand: Hand = .right
    
    var bandOrientation: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
    var mannequinOrientation: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
    
    private let mannequinVerticalAnchor: Float = 0.5
    private var rotateBandStartOrientation: simd_quatf?
    private var rotateGemAnchorStartOrientation: simd_quatf?
    private var rotateMannequinStartOrientation: simd_quatf?
    
    //attach band gem to mannequin
    private var fingerAnchors: [HandFinger: Entity] = [:]
    private let fingerRingScale: [HandFinger: Float] = [
        .rightthumb: 1.30,
        .rightpointer: 1.30,
        .rightmiddle: 1.22,
        .rightring: 1.20,
        .rightpinky: 1.10,

        .leftthumb: 1.30,
        .leftpointer: 1.30,
        .leftmiddle: 1.22,
        .leftring: 1.20,
        .leftpinky: 1.10
    ]
    
    private(set) var bandScale: Float = 1.0
    private let targetBandDiameter: Float = 0.2
    private let targetGemstoneDiameter: Float = 0.1
    private let targetMannequinDiameter: Float = 0.5
    private let gemFrontDepth: Float = 0.01
    private let gemFixedTapPosition = SIMD3<Float>(0.2, 0, 0.001)
    
    private(set) var editorFrameInGlobal: CGRect = .zero
    private(set) var realityContent: RealityViewCameraContent?
    private var isSetup = false
    
    //skincolor
    private(set) var skinColor: UIColor = UIColor(red: 0.79, green: 0.59, blue: 0.41, alpha: 1)
    func applySkinColor(_ color: UIColor) {
        skinColor = color
        for child in mannequinAnchorLeft.children {
            tintMaterials(of: child, with: color)
        }

        for child in mannequinAnchorRight.children {
            tintMaterials(of: child, with: color)
        }
    }
    
    private func tintMaterials(of entity: Entity, with color: UIColor) {
        guard entity !== bandAnchor else { return }
        
        if var model = entity.components[ModelComponent.self] {
            model.materials = model.materials.map { material in
                tinted(material: material, with: color)
            }
            entity.components.set(model)
        }
        for child in entity.children {
            tintMaterials(of: child, with: color)
        }
    }
    
    private func tinted(material: RealityKit.Material, with color: UIColor) -> RealityKit.Material {
        if var pbr = material as? PhysicallyBasedMaterial {
            pbr.baseColor = .init(tint: color)
            return pbr
        }
        if var simple = material as? SimpleMaterial {
            simple.color = .init(tint: color)
            return simple
        }
        if var unlit = material as? UnlitMaterial {
            unlit.color = .init(tint: color) //, texture: unlit.color.texture
            return unlit
        }
        return material
    }
    
    func setEditorFrame(_ frame: CGRect) { editorFrameInGlobal = frame }
    func setRealityContent(_ content: RealityViewCameraContent) { realityContent = content }
    func isInsideEditorFrame(_ globalPoint: CGPoint) -> Bool { editorFrameInGlobal.contains(globalPoint) }
    
    private func returnBandToPivot() {
        guard bandAnchor.parent !== bandPivot else { return }
        bandAnchor.setParent(bandPivot, preservingWorldTransform: false)
        bandAnchor.position = .zero
        bandAnchor.orientation = bandOrientation
        bandAnchor.scale = .one
        gizmoController.updateGizmoTransform()
    }
    
    func setup(bandURL: URL?, bandSource: BandSourceComponent, leftMannequinURL: URL?,
               rightMannequinURL: URL?, gemURLs: [String: URL], mode: JewelryEditorMode, savedGems: [GemComponent], savedBand: BandComponent?) async {
        guard !isSetup else { return }
        isSetup = true
        
        bandPivot.addChild(bandAnchor)
        rootEntity.addChild(bandPivot)
        mannequinPivot.addChild(mannequinAnchorLeft)
        mannequinPivot.addChild(mannequinAnchorRight)
        
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
        
        if let leftMannequinURL {
            await loadMannequin(
                from: leftMannequinURL,
                hand: .left
            )
        } else {
            print("❌ No left mannequin URL")
        }

        if let rightMannequinURL {
            await loadMannequin(
                from: rightMannequinURL,
                hand: .right
            )
        } else {
            print("❌ No right mannequin URL")
        }
        
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
        guard let entity = gizmoController.activeEntity else {
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
        
        if entity.components[GestureComponent].self?.typeJewelry == .gemstone {
            gizmoController.select(entity)
            setSnapPointVisualsVisible(true)
        } else {
            setSnapPointVisualsVisible(false)
        }
    }
    
    func deselectEntity() {
        gizmoController.deselect()
    }
    
    func updateVisibility(for mode: JewelryEditorMode) {
        switch mode {
        case .band:
            returnBandToPivot()
            bandPivot.isEnabled = true
            gemAnchor.isEnabled = true
            mannequinPivot.isEnabled = false
            mannequinAnchorLeft.isEnabled = false
            mannequinAnchorRight.isEnabled = false

        case .handMannequin:
            bandPivot.isEnabled = false
            gemAnchor.isEnabled = false
            mannequinPivot.isEnabled = true
            setSnapPointVisualsVisible(false)
            gizmoController.deselect()
            gizmoController.setTransformTarget(mannequin)
        }
    }
    
    private func updateVisibleHand(for handFinger: HandFinger) {
        activeHand = handFinger.hand

        mannequinAnchorLeft.isEnabled = handFinger.hand == .left
        mannequinAnchorRight.isEnabled = handFinger.hand == .right
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
    
    private func modelBounds(of entity: Entity) -> SIMD3<Float>? {
        if let model = entity.components[ModelComponent.self] {
            return model.mesh.bounds.extents
        }
        
        for child in entity.children {
            if let bounds = modelBounds(of: child) {
                return bounds
            }
        }
        
        return nil
    }
    
    func replaceBand(from localURL: URL, source: BandSourceComponent, saved: BandComponent? = nil) async {
        await loadBand(from: localURL, source: source, saved: nil)
    }
    
    private func captureAttachedGems() -> [PendingGemAttach] {
        guard let bandEntity = bandAnchor.children.first else { return [] }
        let snapPoints = bandEntity.children.filter { $0.components[SnapPointComponent.self] != nil }
        
        var captured: [PendingGemAttach] = []
        for snap in snapPoints {
            guard let snapID = snap.components[SnapPointComponent.self]?.snapID else { continue }
            for child in snap.children where child.components[GestureComponent.self]?.typeJewelry == .gemstone {
                captured.append(PendingGemAttach(entity: child, snapID: snapID))
            }
        }
        return captured
    }
    
    private func prepareAndInstall(band: Entity, saved: BandComponent?) {
        band.position = .zero
        band.orientation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
        band.scale = .init(repeating: 1)
        
        let rawBounds = band.visualBounds(relativeTo: band)
        let rawExtents = rawBounds.extents
        let rawCenter = rawBounds.center
        
        let correction = correctiveOrientation(for: rawExtents)
        band.orientation = correction
        let correctedExtents = abs(correction.act(rawExtents))
        let correctedCenter = correction.act(rawCenter)
        
        let rawDiameter = max(correctedExtents.x, correctedExtents.y)
        guard rawDiameter > 0, rawDiameter.isFinite else {
            print("[BAND] Invalid diameter:", rawDiameter)
            return
        }
        
        let normalizedScale = targetBandDiameter / rawDiameter
        guard normalizedScale.isFinite, normalizedScale > 0 else {
            print("[BAND] Invalid scale:", normalizedScale)
            return
        }
        
        band.scale = .init(repeating: normalizedScale)
        band.position = -correctedCenter * normalizedScale
        band.generateCollisionShapes(recursive: true)
        band.components.set(InputTargetComponent())
    
        SnappingService.addSnapPoints(
            to: band,
            correction: correction,
            canonicalCenter: correctedCenter,
            canonicalExtents: correctedExtents
        )
                
        if let orientation = saved?.orientation {
            bandAnchor.orientation = orientation
        } else {
            bandAnchor.orientation = simd_quatf(
                angle: 0,
                axis: SIMD3<Float>(0, 1, 0)
            )
        }
                
        let captureGems = captureAttachedGems()
        
        for captureGem in captureGems {
            captureGem.entity.setParent(
                gemAnchor,
                preservingWorldTransform: true
            )
        }
        
        bandAnchor.children.removeAll()
        
        bandAnchor.addChild(band)
                
        let newSnapPoints = allSnapPoints()
        
        for capture in captureGems {
            if let target = newSnapPoints.first(where: {
                $0.components[SnapPointComponent.self]?.snapID
                == capture.snapID
            }) {
                SnappingService.attach(
                    gem: capture.entity,
                    to: target
                )
            }
        }
        
        bandOrientation =
        bandAnchor.orientation(relativeTo: nil)
        
        gizmoController.updateGizmoTransform()
    }
    
    private func correctiveOrientation(for extents: SIMD3<Float>) -> simd_quatf {
        let ax = extents.x
        let ay = extents.y
        let az = extents.z

        let branch: String
        let correction: simd_quatf

        if az <= ax && az <= ay {
            branch = "Z"
            correction = simd_quatf(
                angle: 0,
                axis: SIMD3<Float>(0, 1, 0)
            )
        } else if ay <= ax && ay <= az {
            branch = "Y"
            correction = simd_quatf(
                angle: .pi / 2,
                axis: SIMD3<Float>(1, 0, 0)
            )
        } else {
            branch = "X"
            correction = simd_quatf(
                angle: .pi / 2,
                axis: SIMD3<Float>(0, 1, 0)
            )
        }

        print("""
        ========== CORRECTIVE ORIENTATION DEBUG ==========
        Extents   : \(extents)
        ax        : \(ax)
        ay        : \(ay)
        az        : \(az)
        Min Axis  : \(branch)
        Correction: \(correction)
        ===================================================
        """)

        return correction
    }
    
    func allSnapPoints() -> [Entity] {
        guard let bandEntity = bandAnchor.children.first else {
            return []
        }
        
        return bandEntity.children.filter {
            $0.components[SnapPointComponent.self] != nil
        }
    }
    
    func loadMannequin(from localURL: URL, hand: Hand) async -> Entity? {
        do {
            let mannequin = try await Entity(contentsOf: localURL)

            let bounds = mannequin.visualBounds(relativeTo: mannequin)
            let center = bounds.center
            let extents = bounds.extents
            let maxDimension = max(extents.x, max(extents.y, extents.z))

            guard maxDimension > 0, maxDimension.isFinite else {
                print("❌ Invalid mannequin bounds")
                return nil
            }

            let initialScale = targetMannequinDiameter / maxDimension

            mannequin.transform = .identity
            mannequin.scale = .init(repeating: initialScale)

            let anchorLocalY =
                bounds.min.y
                + (bounds.max.y - bounds.min.y) * mannequinVerticalAnchor

            let scaledAnchorY = anchorLocalY * initialScale

            mannequin.position = SIMD3<Float>(
                -center.x * initialScale,
                -scaledAnchorY,
                -center.z * initialScale
            )

            mannequin.generateCollisionShapes(
                recursive: true,
                static: true
            )

            mannequin.components.set(InputTargetComponent())

            mannequin.components.set(
                GestureComponent(
                    typeJewelry: .handMannequin,
                    canDrag: false,
                    canScale: true,
                    canRotate: true
                )
            )

            let targetAnchor =
                hand == .left
                    ? mannequinAnchorLeft
                    : mannequinAnchorRight

            targetAnchor.children.removeAll()
            targetAnchor.addChild(mannequin)

            indexFingerAnchors(
                in: mannequin,
                hand: hand
            )
            applySkinColor(skinColor)

            return mannequin

        } catch {
            print("❌ Failed to load \(hand) mannequin:", error)
            return nil
        }
    }
    
    func addStone(from localURL: URL, source: Gem, screenLocation: CGPoint? = nil, containerSize: CGSize? = nil) async -> Entity? {
        do {
            let gemstone = try await ModelEntity(contentsOf: localURL)
            
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
    
    private func debugEntityHierarchy(_ entity: Entity, level: Int = 0) {
        let indent = String(repeating: "  ", count: level)
        print("\(indent)- \(entity.name)", entity.components[ModelComponent.self] != nil ? "[mesh]" : "")
        for child in entity.children {
            debugEntityHierarchy(child, level: level + 1)
        }
    }
    
    private func applyDebugMaterial(to entity: Entity) {
        if var model = entity.components[ModelComponent.self] {
            model.materials = [
                SimpleMaterial(
                    color: .red,
                    isMetallic: false
                )
            ]
            
            entity.components.set(model)
            
            print("🔴 Debug material applied to:", entity.name)
        }
        
        for child in entity.children {
            applyDebugMaterial(to: child)
        }
    }
    
    private func spawnPosition(screenLocation: CGPoint?, containerSize: CGSize?) -> SIMD3<Float> {
        guard let loc = screenLocation, let size = containerSize, size.width > 0, size.height > 0 else {
            return gemFixedTapPosition
        }
        
        let normalizedX = Float(loc.x / size.width) - 0.5
        
        let normalizedY = Float(loc.y / size.height) - 0.5
        
        return SIMD3<Float>(normalizedX * 0.004, -normalizedY * 0.004, gemFrontDepth)
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
    
//    func rotateSelectedGemAroundViewYAxis(byDegrees delta: Float) {
//        guard let entity = gizmoController.selectedEntity,
//              entity.components[GestureComponent.self]?.typeJewelry == .gemstone else {
//            return
//        }
//        
//        let cameraUpWorld = cameraController.pivot.orientation(relativeTo: nil).act(SIMD3<Float>(1, 0, 0))
//        
//        let rotation = simd_quatf(angle: delta * .pi / 180, axis: normalize(cameraUpWorld))
//        let currentWorldOrientation = entity.orientation(relativeTo: nil)
//        entity.setOrientation(rotation * currentWorldOrientation, relativeTo: nil)
//        gizmoController.updateGizmoTransform()
//    }
    
    func rotateSelectedGemAroundWorldYAxis(byDegrees delta: Float) {
        guard let entity = gizmoController.selectedEntity,
              entity.components[GestureComponent.self]?.typeJewelry == .gemstone else {
            return
        }

        let worldYAxis = SIMD3<Float>(0, 1, 0)

        let rotation = simd_quatf(angle: delta * .pi / 180, axis: worldYAxis)
        let currentWorldOrientation = entity.orientation(relativeTo: nil)
        entity.setOrientation(rotation * currentWorldOrientation, relativeTo: nil)
        gizmoController.updateGizmoTransform()
    }
    
    func rotateSelectedGem(byDegrees delta: Float) {
        guard let entity = gizmoController.selectedEntity,
              entity.components[GestureComponent.self]?.typeJewelry == .gemstone else {
            return
        }

        let snapPoint = entity.parent
        let snapComponent = snapPoint?.components[SnapPointComponent.self]

        if let snapPoint, let snapComponent {
            let localYRotation = simd_quatf(angle: delta * .pi / 180, axis: SIMD3<Float>(0, 1, 0))
            entity.orientation = entity.orientation * localYRotation
            let parentWorldScale = snapPoint.scale(relativeTo: nil)
            let standoffLocal = snapComponent.standoffDistance / parentWorldScale.z
            let boundsInSnap = entity.visualBounds(relativeTo: snapPoint)
            let gemHalfDepth = boundsInSnap.extents.z / 2
            entity.position = SIMD3<Float>(0, 0, standoffLocal + gemHalfDepth)
        } else {
            let rotationAxis = normalize(
                cameraController.pivot.orientation(relativeTo: nil).act(SIMD3<Float>(0, 1, 0))
            )
            let rotation = simd_quatf(angle: delta * .pi / 180, axis: rotationAxis)
            let currentWorldOrientation = entity.orientation(relativeTo: nil)
            entity.setOrientation(rotation * currentWorldOrientation, relativeTo: nil)
        }

        gizmoController.updateGizmoTransform()
    }
    
    func rotateSelectedGemAroundViewXAxis(byDegrees delta: Float) {
        guard let entity = gizmoController.selectedEntity,
              entity.components[GestureComponent.self]?.typeJewelry == .gemstone else {
            return
        }
        
        let cameraUpWorld = cameraController.pivot.orientation(relativeTo: nil).act(SIMD3<Float>(0, 1, 0))
        
        let rotation = simd_quatf(angle: delta * .pi / 180, axis: normalize(cameraUpWorld))
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
    
    func updateGizmoTarget(for mode: JewelryEditorMode) {

        if let selected = gizmoController.selectedEntity,
           selected.components[GestureComponent.self]?.typeJewelry == .gemstone {

            gizmoController.setTransformTarget(selected)
            return
        }

        switch mode {
        case .band:
            gizmoController.setTransformTarget(bandAnchor)

        case .handMannequin:
            gizmoController.setTransformTarget(mannequin)
        }
    }
    
    func beginRotateMannequin() {
        rotateMannequinStartOrientation = mannequinPivot.orientation(relativeTo: nil)
    }

    func rotateMannequin(deltaX: Float, deltaY: Float) {
        guard let startOrientation = rotateMannequinStartOrientation else {
            rotateMannequinStartOrientation =
                mannequinPivot.orientation(relativeTo: nil)
            return
        }

        let rotationY = deltaX * 0.01
        let rotationX = deltaY * 0.01

        let qY = simd_quatf(
            angle: rotationY,
            axis: SIMD3<Float>(0, 1, 0)
        )

        let qX = simd_quatf(
            angle: rotationX,
            axis: SIMD3<Float>(1, 0, 0)
        )

        let delta = qY * qX

        mannequinPivot.orientation = delta * startOrientation
        mannequinOrientation = mannequinPivot.orientation(relativeTo: nil)

        gizmoController.updateGizmoTransform()
    }

    func snapMannequin(to targetOrientation: simd_quatf) {
        mannequinPivot.orientation = targetOrientation
        mannequinOrientation = mannequinPivot.orientation(relativeTo: nil)
        gizmoController.updateGizmoTransform()
    }

    func endRotateMannequin() {
        rotateMannequinStartOrientation = nil
    }
    
    private func indexFingerAnchors(in mannequin: Entity, hand: Hand) {
        for finger in Finger.allCases {
            let handFinger = HandFinger.from(
                hand: hand,
                finger: finger
            )

            let anchorName = "anchor_\(handFinger.rawValue)"

            if let anchor = mannequin.findEntity(named: anchorName) {
                fingerAnchors[handFinger] = anchor
                print(
                    "✅ Indexed:",
                    handFinger.rawValue,
                    "→",
                    anchor.name
                )
            } else {
                print(
                    "⚠️ Missing finger anchor:",
                    anchorName
                )
            }
        }
    }
    
    func isPlacementAvailable(for handFinger: HandFinger) -> Bool {
        fingerAnchors[handFinger] != nil
    }

    func attachBandToFinger(_ handFinger: HandFinger) {
        guard let anchor = fingerAnchors[handFinger] else {
            print("⚠️ \(handFinger.title) belum memiliki placement anchor")
            return
        }

        if bandAnchor.parent === bandPivot {
            bandOrientation = bandAnchor.orientation(relativeTo: nil)
            bandScale = bandAnchor.scale.x
        }

        updateVisibleHand(for: handFinger)

        bandAnchor.setParent(anchor, preservingWorldTransform: false)
        bandAnchor.position = .zero
        bandAnchor.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])

        let fingerFactor = fingerRingScale[handFinger] ?? 1.0
        bandAnchor.scale = .init(repeating: bandScale * fingerFactor)

        gizmoController.updateGizmoTransform()

        print("✅ Band placed on:", handFinger.rawValue)
    }
}
