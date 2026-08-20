//
//  SnappingService.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 15/08/26.
//

import Foundation
import SwiftUI
import RealityKit
import simd

enum SnappingService {
    static let snapPointIDs = ["band-snap-0", "band-snap-1", "band-snap-2"]
    
    static let defaultDragScreenRadius: CGFloat = 50

    static func nearestSnapPoint(to gem: Entity, among snapPoints: [Entity], maxDistance: Float, allowOccupiedBySelf gemName: String) -> Entity? {
        let gemWorldPosition = gem.position(relativeTo: nil)

        var best: Entity?
        var bestDistanceSq = maxDistance * maxDistance

        for snap in snapPoints {
            guard let component = snap.components[SnapPointComponent.self] else {
                continue
            }

            if let occupant = component.occupiedByGemName, occupant != gemName {
                continue
            }

            let snapWorldPosition = snap.position(relativeTo: nil)
            let distanceSq = simd_length_squared(snapWorldPosition - gemWorldPosition)

            if distanceSq < bestDistanceSq {
                bestDistanceSq = distanceSq
                best = snap
            }
        }

        return best
    }
    static func attach(gem: Entity, to snapPoint: Entity) {
        guard var snapComponent = snapPoint.components[SnapPointComponent.self] else {
            return
        }

        if let occupant = snapComponent.occupiedByGemName, occupant != gem.name {
            return
        }

        let worldScaleBefore = gem.scale(relativeTo: nil)

        gem.setParent(snapPoint, preservingWorldTransform: false)

        gem.orientation = snapComponent.localOrientationCorrection

        let parentWorldScale = snapPoint.scale(relativeTo: nil)
        gem.scale = worldScaleBefore / parentWorldScale

        let gemBoundsInSnap = gem.visualBounds(relativeTo: snapPoint)
        let gemHalfDepth = gemBoundsInSnap.extents.z / 2
        let standoffLocal = snapComponent.standoffDistance / parentWorldScale.z

        gem.position = SIMD3<Float>(0, 0, standoffLocal + gemHalfDepth)

        snapComponent.occupiedByGemName = gem.name
        snapPoint.components[SnapPointComponent.self] = snapComponent

        var attachment = gem.components[AttachmentComponent.self] ?? AttachmentComponent()
        attachment.attachedSnapID = snapComponent.snapID
        gem.components[AttachmentComponent.self] = attachment

        var gesture = gem.components[GestureComponent.self] ?? GestureComponent(typeJewelry: .gemstone)
        gesture.canDrag = true
        gesture.canScale = false
        gesture.canRotate = false
        gem.components[GestureComponent.self] = gesture

    }

    static func detach(gem: Entity, backTo freeAnchor: Entity) {
        guard
            var attachment = gem.components[AttachmentComponent.self],
            let snapID = attachment.attachedSnapID,
            let snapPoint = gem.parent,
            var snapComponent = snapPoint.components[SnapPointComponent.self],
            snapComponent.snapID == snapID
        else {
            return
        }
        
        //edited scale
        let worldScale = gem.scale(relativeTo: nil)
        gem.setParent(freeAnchor, preservingWorldTransform: true)
        let parentWorldScale = freeAnchor.scale(relativeTo: nil)
        gem.scale = worldScale / parentWorldScale
        
        //original scale
//        gem.setParent(freeAnchor, preservingWorldTransform: true)
//        let parentWorldScale = freeAnchor.scale(relativeTo: nil)
//        gem.scale = SIMD3<Float>(repeating: attachment.targetWorldScale) / parentWorldScale

        snapComponent.occupiedByGemName = nil
        snapPoint.components[SnapPointComponent.self] = snapComponent

        attachment.attachedSnapID = nil
        
        //edited scale
        attachment.targetWorldScale = (worldScale.x + worldScale.y + worldScale.z) / 3
        
        gem.components[AttachmentComponent.self] = attachment

        var gesture = gem.components[GestureComponent.self] ?? GestureComponent(typeJewelry: .gemstone)
        gesture.canDrag = true
        gesture.canScale = false
        gesture.canRotate = false
        gem.components[GestureComponent.self] = gesture
    }
    
    static func isAttached(_ gem: Entity) -> Bool {
        guard let attachment = gem.components[AttachmentComponent.self] else {
            return false
        }
        return attachment.attachedSnapID != nil
    }
    
    static func reapplyFixedScale(for gem: Entity) {
        guard
            let fixed = gem.components[AttachmentComponent.self],
            let snapPoint = gem.parent,
            let snapComponent = snapPoint.components[SnapPointComponent.self]
        else {
            return
        }

        let parentWorldScale = snapPoint.scale(relativeTo: nil)

        gem.scale = SIMD3<Float>(repeating: fixed.targetWorldScale) / parentWorldScale

        let gemBoundsInSnap = gem.visualBounds(relativeTo: snapPoint)
        let gemHalfDepth = gemBoundsInSnap.extents.z / 2
        let standoffLocal = snapComponent.standoffDistance / parentWorldScale.z

        gem.position = SIMD3<Float>(0, 0, standoffLocal + gemHalfDepth)
    }

    static func addSnapPoints(to band: Entity) {
        let bounds = band.visualBounds(relativeTo: band)
        let center = bounds.center

        let ringRadius = max(bounds.extents.x, bounds.extents.y) / 2

        let angles: [(id: String, degrees: Float)] = [
            ("band-snap-0", -25),
            ("band-snap-1", 0),
            ("band-snap-2", 25)
        ]

        for (index, entry) in angles.enumerated() {
            let radians = entry.degrees * .pi / 180

            let snap = Entity()
            snap.name = entry.id

            snap.position = SIMD3<Float>(
                center.x + sin(radians) * ringRadius,
                center.y + cos(radians) * ringRadius,
                center.z
            )

            let radialDirection = SIMD3<Float>(
                sin(radians),
                cos(radians),
                0
            )

            snap.orientation = simd_quatf(
                from: [0, 0, 1],
                to: normalize(radialDirection)
            )

            snap.components.set(
                SnapPointComponent(
                    snapID: entry.id,
                    index: index
                )
            )

            let visual = ModelEntity(
                mesh: .generateSphere(radius: 5),
                materials: [
                    SimpleMaterial(
                        color: .blue.withAlphaComponent(0.3),
                        isMetallic: false
                    )
                ]
            )

            visual.name = "snap-visual"
            visual.position = SIMD3<Float>(0, 2, 20)
            visual.isEnabled = false

            snap.addChild(visual)
            band.addChild(snap)
        }
    }
    
    static func nearestSnapForDrag(gem: Entity, fingerLocal: CGPoint, snapPoints: [Entity], realityContent: RealityViewCameraContent, maxScreenDistance: CGFloat) -> Entity? {
        guard gem.components[GestureComponent.self]?.typeJewelry == .gemstone else {
            return nil
        }
        guard !snapPoints.isEmpty else {
            return nil
        }

        var nearest: Entity?
        var nearestDistance: CGFloat = .greatestFiniteMagnitude

        for snap in snapPoints {
            guard let snapComponent = snap.components[SnapPointComponent.self] else {
                continue
            }
            if let occupant = snapComponent.occupiedByGemName, occupant != gem.name {
                continue
            }

            let snapWorldPosition = snap.position(relativeTo: nil)
            guard let snapScreenPosition = realityContent.project(point: snapWorldPosition, to: .local) else {
                continue
            }

            let dx = snapScreenPosition.x - fingerLocal.x
            let dy = snapScreenPosition.y - fingerLocal.y
            let distance = hypot(dx, dy)

            if distance < nearestDistance {
                nearestDistance = distance
                nearest = snap
            }
        }

        guard let nearest, nearestDistance <= maxScreenDistance else {
            return nil
        }
        return nearest
    }
}
