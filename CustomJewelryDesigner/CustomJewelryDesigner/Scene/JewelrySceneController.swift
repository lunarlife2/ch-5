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
    
    private let targetBandDiameter: Float = 0.004
    private let targetGemstoneDiameter: Float = 0.004
    private let targetMannequinDiameter: Float = 0.008
    private let gemFrontDepth: Float = 0.03
    private let gemFixedTapPosition = SIMD3<Float>(0.4, 0.5, 0)

    private(set) var editorFrameInGlobal: CGRect = .zero
    private(set) var realityContent: RealityViewCameraContent?
    private var isSetup = false

    func setEditorFrame(_ frame: CGRect) { editorFrameInGlobal = frame }
    func setRealityContent(_ content: RealityViewCameraContent) { realityContent = content }

    func setup(bandURL: URL, bandSource: BandSourceComponent, gemURLs: [String: URL], mode: JewelryEditorMode, savedGems: [GemComponent], savedBand: BandComponent?) async {
        guard !isSetup else { return }
        isSetup = true
        
        bandPivot.addChild(bandAnchor)
        rootEntity.addChild(bandPivot)
        mannequinPivot.addChild(mannequinAnchor)
        rootEntity.addChild(mannequinPivot)
        rootEntity.addChild(gemAnchor)
        
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

        await loadBand(from: bandURL, source: bandSource, saved: savedBand)
        await loadMannequin()
        await loadSavedGems(gems: savedGems, urls: gemURLs)
        updateVisibility(for: mode)
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
        let size = band.visualBounds(relativeTo: nil).extents

        let scale =
            targetBandDiameter /
            max(size.x, size.y)

        band.scale = .init(repeating: scale)
        band.position = [-0.001, 0, 0]

        band.generateCollisionShapes(recursive: true)

        band.components.set(
            InputTargetComponent()
        )

        band.components.set(
            GestureComponent(
                typeJewelry: .band,
                canDrag: false,
                canScale: true,
                canRotate: true
            )
        )

        SnappingService.addSnapPoints(to: band)

        if let saved {
            if let orientation = saved.orientation {
                band.orientation = orientation
            }

            if let scale = saved.scaleFactor {
                band.scale = .init(repeating: Float(scale))
            }
        }

        bandAnchor.children.removeAll()
        bandAnchor.addChild(band)
    }

    func loadMannequin() async {
        do {
            let mannequin = try await Entity(named: "Simplified_Hand_For_Artists")

            let mannequinSize = mannequin.visualBounds(relativeTo: nil).extents
            mannequin.scale = .init(repeating: targetMannequinDiameter / max(mannequinSize.x, mannequinSize.y))
            mannequin.position = [0, -0.5, 0]

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
        } catch {
            print("Failed to load entity", error)
        }
    }

    func addStone(from localURL: URL, source: Gem, screenLocation: CGPoint? = nil, containerSize: CGSize? = nil) async -> Entity? {
        do {
            let gemstone = try await ModelEntity(contentsOf: localURL)
            let gemstoneSize = gemstone.visualBounds(relativeTo: nil).extents

            let initialScale = targetGemstoneDiameter / max(gemstoneSize.x, gemstoneSize.y)
            gemstone.scale = .init(repeating: initialScale)
            gemstone.components.set(AttachmentComponent(targetWorldScale: initialScale))

            // BARU — simpen asal-usul gem ini
            gemstone.components.set(GemSourceComponent(
                libraryAssetID: source.id,
                assetStoragePath: source.assetId.storagePath,
                cut: source.gemShape,
                color: source.gemMaterial
            ))

            gemstone.name = UUID().uuidString
            gemstone.position = spawnPosition(screenLocation: screenLocation, containerSize: containerSize)
            gemstone.generateCollisionShapes(recursive: true)
            gemstone.components.set(InputTargetComponent())
            gemstone.components.set(
                GestureComponent(typeJewelry: .gemstone, canDrag: true, canScale: false, canRotate: true)
            )

            gemAnchor.addChild(gemstone)
            return gemstone
        } catch {
            print("Failed to load entity", error)
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
        guard let loc = screenLocation, let size = containerSize else {
            return gemFixedTapPosition
        }

        let nx = Float(loc.x / size.width) - 0.9
        let ny = Float(loc.y / size.height) - 0.9

        return SIMD3<Float>(nx * 0.04, ny * 0.04, gemFrontDepth)
    }
    
    func allSnapPoints() -> [Entity] {
        guard let bandEntity = bandAnchor.children.first else {
            return []
        }

        return bandEntity.children.filter {
            $0.components[SnapPointComponent.self] != nil
        }
    }
}
