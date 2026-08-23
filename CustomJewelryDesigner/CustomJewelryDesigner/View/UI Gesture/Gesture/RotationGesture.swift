//
//  RotationGesture.swift
//  tesJewelryDesign
//
//  Created by Yimei Winata on 06/08/26.
//


import Foundation
import RealityKit
import SwiftUI

struct RingRotationGesture {

    let touchTracker: TouchCountViewModel
    let editViewModel: EditViewModel
    let scene: JewelrySceneController
    private let rotationSensitivity: Float = 0.01

    var rotateGesture: some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .targetedToAnyEntity()
            .onChanged { value in
                guard let hitEntity = value.entity.gestureTarget() else {
                    return
                }

                guard let gc = hitEntity.components[GestureComponent.self],
                      (gc.typeJewelry == .band || gc.typeJewelry == .handMannequin),
                      gc.canRotate
                else {
                    return
                }

                let target: Entity

                switch gc.typeJewelry {
                case .band:
                    target = scene.bandAnchor

                case .handMannequin:
                    target = scene.mannequin

                default:
                    return
                }

                var state = target.gestureStateComponent

                if !state.isRotating {
                    guard touchTracker.activeTouchCount == 1 else {
                        return
                    }

                    state.isRotating = true
                    state.lastRotateHorizontalX = Float(value.location.x)
                    state.lastRotateVerticalY = Float(value.location.y)

                    target.gestureStateComponent = state
                    return
                }

                guard touchTracker.activeTouchCount == 1 else {
                    state.isRotating = false
                    target.gestureStateComponent = state
                    return
                }

                let currentX = Float(value.location.x)
                let currentY = Float(value.location.y)

                let deltaX = currentX - state.lastRotateHorizontalX
                let deltaY = currentY - state.lastRotateVerticalY

                state.lastRotateHorizontalX = currentX
                state.lastRotateVerticalY = currentY

                let qY = simd_quatf(
                    angle: deltaX * rotationSensitivity,
                    axis: SIMD3<Float>(0, 1, 0)
                )

                let qX = simd_quatf(
                    angle: deltaY * rotationSensitivity,
                    axis: SIMD3<Float>(1, 0, 0)
                )

                target.orientation = qY * qX * target.orientation

                state.lastRotate = target.orientation(relativeTo: nil)
                target.gestureStateComponent = state

                switch gc.typeJewelry {
                case .band:
                    scene.bandOrientation = target.orientation(relativeTo: nil)

                case .handMannequin:
                    scene.mannequinOrientation = target.orientation(relativeTo: nil)

                default:
                    break
                }

                scene.gizmoController.updateGizmoTransform()
            }
            .onEnded { value in
                guard let hitEntity = value.entity.gestureTarget() else {
                    return
                }

                guard let gc = hitEntity.components[GestureComponent.self],
                      (gc.typeJewelry == .band || gc.typeJewelry == .handMannequin)
                else {
                    return
                }

                let target: Entity

                switch gc.typeJewelry {
                case .band:
                    target = scene.bandAnchor

                case .handMannequin:
                    target = scene.mannequin

                default:
                    return
                }

                var state = target.gestureStateComponent
                state.isRotating = false
                state.lastRotate = target.orientation(relativeTo: nil)
                target.gestureStateComponent = state

                editViewModel.markDirty()
            }
    }
}
