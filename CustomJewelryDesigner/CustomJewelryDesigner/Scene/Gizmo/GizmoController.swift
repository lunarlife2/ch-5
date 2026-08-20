//
//  GizmoController.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 18/08/26.
//

import Foundation
import RealityKit
import simd

@MainActor
final class GizmoController {

    let gizmo: TransformGizmo

    let selectionWireframe: SelectionWireframe

    weak var targetEntity: Entity?

    var mode: GizmoTransformMode = .translate

    var selectedHandle: GizmoHandle?
    
    private(set) var selectedEntity: Entity?

    init() {

        gizmo = TransformGizmo()

        selectionWireframe = SelectionWireframe()

        gizmo.isEnabled = false
        selectionWireframe.isEnabled = false
    }

    func install(in rootEntity: Entity) {
        if gizmo.parent == nil {
            rootEntity.addChild(gizmo)
        }

        if selectionWireframe.parent == nil {
            rootEntity.addChild(selectionWireframe)
        }
    }


    func select(_ entity: Entity) {
        if targetEntity === entity {
            selectionWireframe.refresh()
            return
        }

        selectionWireframe.hide()

        targetEntity = entity
        selectedEntity = entity
        selectedHandle = nil

        selectionWireframe.show(for: entity)

        gizmo.isEnabled = false

        updateGizmoTransform()
    }

    func deselect() {
        selectionWireframe.hide()

        targetEntity = nil
        selectedEntity = nil
        selectedHandle = nil

        gizmo.isEnabled = false
    }


    func select(entityAtScreenLocation entity: Entity?) {
        guard let entity else {
            deselect()
            return
        }
        select(entity)
    }

    func updateSelectionWireframeTransform() {
        guard let selectedEntity else {
            selectionWireframe.hide()
            return
        }

        // Target sudah tidak ada di hierarchy scene
        guard selectedEntity.scene != nil else {
            deselect()
            return
        }

        let worldPosition = selectedEntity.position(relativeTo: nil)
        let worldOrientation = selectedEntity.orientation(relativeTo: nil)
        let worldScale = selectedEntity.scale(relativeTo: nil)

        selectionWireframe.setPosition(
            worldPosition,
            relativeTo: nil
        )

        selectionWireframe.setOrientation(
            worldOrientation,
            relativeTo: nil
        )

        selectionWireframe.setScale(
            worldScale,
            relativeTo: nil
        )

        selectionWireframe.refresh()
    }
    
    func updateGizmoTransform() {
        guard let selectedEntity else {
            gizmo.isEnabled = false
            return
        }

        let worldPosition =
            selectedEntity.position(relativeTo: nil)

        let worldOrientation =
            selectedEntity.orientation(relativeTo: nil)

        gizmo.setPosition(
            worldPosition,
            relativeTo: nil
        )

        gizmo.setOrientation(
            worldOrientation,
            relativeTo: nil
        )

        gizmo.setScale(
            SIMD3<Float>(
                repeating: calculateGizmoScale()
            ),
            relativeTo: nil
        )

        updateSelectionWireframeTransform()
    }
    
    func handleSelected(_ handle: GizmoHandle) {
        selectedHandle = handle

        print("Gizmo handle selected:", handle)
    }

    func clearHandleSelection() {
        selectedHandle = nil
    }

    private func calculateGizmoScale() -> Float {

        return 1.0
    }
}
