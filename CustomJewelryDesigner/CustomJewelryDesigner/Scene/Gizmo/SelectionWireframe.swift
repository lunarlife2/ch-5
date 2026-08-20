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

    var wireColor: UIColor = .systemOrange
    var surfaceScale: Float = 1.0015
    private weak var targetEntity: Entity?

    required init() {
        super.init()

        name = "SelectionWireframe"
        isEnabled = false
    }


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


    private func rebuild(from target: Entity) {
        removeAllChildren()
        let wireMaterial = makeWireMaterial()
        collectModels(
            from: target,
            target: target,
            wireMaterial: wireMaterial
        )
    }

    private func collectModels(from entity: Entity, target: Entity, wireMaterial: UnlitMaterial) {
        if let modelEntity = entity as? ModelEntity {
            addWireframeModel(from: modelEntity, target: target, wireMaterial: wireMaterial)
        }
        for child in entity.children {

            collectModels(from: child, target: target, wireMaterial: wireMaterial)
        }
    }

    private func addWireframeModel(from original: ModelEntity, target: Entity, wireMaterial: UnlitMaterial) {
        guard let modelComponent = original.components[ModelComponent.self] else {
            return
        }
        let materialCount = max(modelComponent.materials.count, modelComponent.mesh.expectedMaterialCount)

        let materials: [any Material]

        if materialCount > 0 {
            materials = Array(repeating: wireMaterial, count: materialCount)
        } else {
            materials = [wireMaterial]
        }

        let wireModel = ModelEntity(mesh: modelComponent.mesh, materials: materials)

        wireModel.name = "\(original.name)_Wireframe"

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

        wireModel.components.remove(CollisionComponent.self)

        wireModel.components.remove(InputTargetComponent.self)

        addChild(wireModel)
    }

    private func makeWireMaterial() -> UnlitMaterial {

        var material = UnlitMaterial(color: wireColor)

        material.triangleFillMode = .lines

        material.writesDepth = false
        material.readsDepth = true

        return material
    }


    private func removeAllChildren() {
        let children = Array(children)
        for child in children {
            child.removeFromParent()
        }
    }
}
