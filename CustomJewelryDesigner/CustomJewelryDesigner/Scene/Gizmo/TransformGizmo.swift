//
//  TransformGizmo.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 18/08/26.
//

import RealityKit
import UIKit
import simd

final class TransformGizmo: Entity {
    
    private let visualRoot = Entity()
        
    let xAxis = Entity()
    let yAxis = Entity()
    let zAxis = Entity()
    
    let xRing = Entity()
    let yRing = Entity()
    let zRing = Entity()
        
    var gizmoSize: Float = 0.15
        
    required init() {
        super.init()
        
        addChild(visualRoot)
        addChild(xRing)
        addChild(yRing)
        addChild(zRing)
        
        buildTranslationGizmo()
        setupInteraction()
    }
        
    private func buildTranslationGizmo() {
        buildXAxis()
        buildYAxis()
        buildZAxis()
    }
        
    private func buildXAxis() {
        let shaft = makeShaft(
            length: gizmoSize,
            axis: .x,
            color: .red
        )
        
        let arrow = makeArrowHead(
            axis: .x,
            color: .red
        )
        
        xAxis.addChild(shaft)
        xAxis.addChild(arrow)
        
        visualRoot.addChild(xAxis)
    }
        
    private func buildYAxis() {
        let shaft = makeShaft(
            length: gizmoSize,
            axis: .y,
            color: .green
        )
        
        let arrow = makeArrowHead(
            axis: .y,
            color: .green
        )
        
        yAxis.addChild(shaft)
        yAxis.addChild(arrow)
        
        visualRoot.addChild(yAxis)
    }
    private func buildZAxis() {
        let shaft = makeShaft(
            length: gizmoSize,
            axis: .z,
            color: .blue
        )
        
        let arrow = makeArrowHead(
            axis: .z,
            color: .blue
        )
        
        zAxis.addChild(shaft)
        zAxis.addChild(arrow)
        
        visualRoot.addChild(zAxis)
    }
    
    private func makeShaft(
        length: Float,
        axis: Axis,
        color: UIColor
    ) -> ModelEntity {
        
        let thickness: Float = 0.008
        
        let mesh = MeshResource.generateBox(
            size: SIMD3<Float>(
                axis == .x ? length : thickness,
                axis == .y ? length : thickness,
                axis == .z ? length : thickness
            )
        )
        
        let material = SimpleMaterial(
            color: color,
            isMetallic: false
        )
        
        let entity = ModelEntity(
            mesh: mesh,
            materials: [material]
        )
        
        switch axis {
        case .x:
            entity.position.x = length / 2
            
        case .y:
            entity.position.y = length / 2
            
        case .z:
            entity.position.z = length / 2
        }
        
        return entity
    }
        
    private func makeArrowHead(
        axis: Axis,
        color: UIColor
    ) -> ModelEntity {
        
        let coneRadius: Float = 0.018
        let coneHeight: Float = 0.04
        
        let mesh = MeshResource.generateCone(
            height: coneHeight,
            radius: coneRadius
        )
        
        let material = SimpleMaterial(
            color: color,
            isMetallic: false
        )
        
        let entity = ModelEntity(
            mesh: mesh,
            materials: [material]
        )
        
        switch axis {
        case .x:
            entity.position.x = gizmoSize + coneHeight / 2
            
            entity.orientation = simd_quatf(
                angle: .pi / 2,
                axis: SIMD3<Float>(0, 0, 1)
            )
            
        case .y:
            entity.position.y = gizmoSize + coneHeight / 2
            
        case .z:
            entity.position.z = gizmoSize + coneHeight / 2
            
            entity.orientation = simd_quatf(
                angle: -.pi / 2,
                axis: SIMD3<Float>(1, 0, 0)
            )
        }
        
        return entity
    }
    
    private func setupInteraction() {
        setupHandle(
            xAxis,
            handle: .xAxis
        )
        
        setupHandle(
            yAxis,
            handle: .yAxis
        )
        
        setupHandle(
            zAxis,
            handle: .zAxis
        )
    }
    
    private func setupHandle(
        _ entity: Entity,
        handle: GizmoHandle
    ) {
        entity.components.set(
            InputTargetComponent()
        )
        
        entity.components.set(
            CollisionComponent(
                shapes: [
                    .generateBox(
                        size: SIMD3<Float>(
                            0.08,
                            0.08,
                            0.08
                        )
                    )
                ]
            )
        )
    }
    
    private enum Axis {
        case x
        case y
        case z
    }
}
