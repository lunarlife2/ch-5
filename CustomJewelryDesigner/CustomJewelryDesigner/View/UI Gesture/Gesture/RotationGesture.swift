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
                guard let entity = value.entity.gestureTarget() else { return }

                guard let gc = entity.components[GestureComponent.self],
                      gc.typeJewelry == .band,
                      gc.canRotate
                else { return }

                var state = entity.gestureStateComponent

                if !state.isRotating {
                    guard touchTracker.activeTouchCount == 1 else { return }

                    state.isRotating = true
                    state.startOrientationRotate = entity.orientation(relativeTo: nil)
                    state.lastRotateHorizontalX = Float(value.location.x)
                    state.lastRotateVerticalY = Float(value.location.y)   // <— tambah ini
                    entity.gestureStateComponent = state
                    return
                }

                guard touchTracker.activeTouchCount == 1 else {
                    state.isRotating = false
                    entity.gestureStateComponent = state
                    return
                }

                let currentX = Float(value.location.x)
                let currentY = Float(value.location.y)

                let deltaX = currentX - state.lastRotateHorizontalX
                let deltaY = currentY - state.lastRotateVerticalY

                state.lastRotateHorizontalX = currentX
                state.lastRotateVerticalY = currentY

                let rotationY = deltaX * rotationSensitivity   // yaw
                let rotationX = deltaY * rotationSensitivity   // pitch

                let qY = simd_quatf(angle: rotationY, axis: SIMD3<Float>(0, 1, 0))
                let qX = simd_quatf(angle: rotationX, axis: SIMD3<Float>(1, 0, 0))

                let currentOrientation = entity.orientation(relativeTo: nil)
                let newOrientation = qY * qX * currentOrientation

                entity.setOrientation(newOrientation, relativeTo: nil)

                state.lastRotate = newOrientation
                state.cumulativeRotationY += rotationY
                entity.gestureStateComponent = state

                scene.bandOrientation = entity.orientation(relativeTo: nil)
                scene.gizmoController.updateGizmoTransform()
            }
            .onEnded { value in
                guard let entity = value.entity.gestureTarget() else { return }

                var state = entity.gestureStateComponent
                guard state.isRotating else { return }

                state.lastRotate = entity.orientation(relativeTo: nil)
                state.isRotating = false
                entity.gestureStateComponent = state

                editViewModel.markDirty()
            }
    }
}
