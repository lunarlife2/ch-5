//
//  SelectionWireframe.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 18/08/26.
//

import Foundation
import RealityKit
import UIKit
import simd

@MainActor
final class SelectionWireframe: Entity {

    // MARK: - Configuration

    var wireColor: UIColor = .systemOrange

    /// Slightly enlarges the wireframe so it sits above
    /// the original mesh and reduces z-fighting.
    var surfaceScale: Float = 1.0015

    // MARK: - Private

    private weak var targetEntity: Entity?

    // MARK: - Init

    required init() {
        super.init()

        name = "SelectionWireframe"

        // This entity is only visual.
        // We don't want it to participate in hit testing.
        isEnabled = false
    }

    // MARK: - Public API

    func show(for target: Entity) {

        hide()

        targetEntity = target

        rebuild(from: target)

        isEnabled = true
    }

    func hide() {

        removeAllChildren()

        targetEntity = nil

        isEnabled = false
    }

    func refresh() {

        guard let targetEntity else {
            return
        }

        rebuild(from: targetEntity)
    }

    // MARK: - Build

    private func rebuild(from target: Entity) {

        removeAllChildren()

        let wireMaterial = makeWireMaterial()

        collectModels(
            from: target,
            target: target,
            wireMaterial: wireMaterial
        )

        /*
         Important:

         SelectionWireframe is a child of the selected entity.

         Therefore the selected entity's transform should NOT
         be copied to SelectionWireframe itself.

         Only the transforms of its ModelEntity descendants
         are copied into the wireframe hierarchy.
        */
    }

    private func collectModels(
        from entity: Entity,
        target: Entity,
        wireMaterial: UnlitMaterial
    ) {

        if let modelEntity = entity as? ModelEntity {

            addWireframeModel(
                from: modelEntity,
                target: target,
                wireMaterial: wireMaterial
            )
        }

        for child in entity.children {

            collectModels(
                from: child,
                target: target,
                wireMaterial: wireMaterial
            )
        }
    }

    // MARK: - Model

    private func addWireframeModel(
        from original: ModelEntity,
        target: Entity,
        wireMaterial: UnlitMaterial
    ) {

        guard let modelComponent = original.components[ModelComponent.self] else {
            return
        }

        let materialCount = max(
            modelComponent.materials.count,
            modelComponent.mesh.expectedMaterialCount
        )

        let materials: [any Material]

        if materialCount > 0 {
            materials = Array(
                repeating: wireMaterial,
                count: materialCount
            )
        } else {
            materials = [wireMaterial]
        }

        let wireModel = ModelEntity(
            mesh: modelComponent.mesh,
            materials: materials
        )

        wireModel.name = "\(original.name)_Wireframe"

        /*
         IMPORTANT:

         The original model can be nested several levels deep.

         We therefore convert its local transform into the
         coordinate space of the selected target.
        */

        if original === target {

            wireModel.transform = .identity

        } else if let parent = original.parent {

            wireModel.transform = target.convert(
                transform: original.transform,
                from: parent
            )

        } else {

            wireModel.transform = .identity
        }

        /*
         Prevent the wireframe from becoming an input target.

         It has no InputTargetComponent and no CollisionComponent,
         so RealityView entity(at:) will not use it as an interaction
         target.
        */

        wireModel.components.remove(
            CollisionComponent.self
        )

        wireModel.components.remove(
            InputTargetComponent.self
        )

        addChild(wireModel)
    }

    // MARK: - Material

    private func makeWireMaterial() -> UnlitMaterial {

        var material = UnlitMaterial(
            color: wireColor
        )

        /*
         THIS is the important part.

         RealityKit renders the mesh as wireframe instead
         of filled triangles.
        */
        material.triangleFillMode = .lines

        /*
         Unlit means the selection lines don't depend on
         lighting in the scene.
        */
        material.writesDepth = false
        material.readsDepth = true

        return material
    }

    // MARK: - Helpers

    private func removeAllChildren() {

        let children = Array(children)

        for child in children {
            child.removeFromParent()
        }
    }
}
