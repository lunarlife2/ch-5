//
//  MagnifyingGesture.swift
//  tesJewelryDesign
//
//  Created by Yimei Winata on 06/08/26.
//

import SwiftUI
import RealityKit

struct MagnifyingGesture {

    let touchTracker: TouchCountViewModel
    let editViewModel: EditViewModel
    let scene: JewelrySceneController
    let tutorial: TutorialController

    private let minScale: Float = 0.3
    private let maxScale: Float = 3.0

    var zoomGesture: some Gesture {
        MagnifyGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                guard let entity = value.entity.gestureTarget() else {
                    return
                }

                guard touchTracker.activeTouchCount == 2 else {
                    TransformSession.shared.forceEndIfStuck()
                    return
                }

                guard let gc = entity.components[GestureComponent.self],
                      gc.canScale else {
                    return
                }

                var state = entity.gestureStateComponent

                if !state.isScaling {
                    guard TransformSession.shared.begin(entity) else {
                        return
                    }

                    state = entity.gestureStateComponent
                    state.isScaling = true
                    state.isRotating = false
                    state.startScale = entity.scale
                    entity.gestureStateComponent = state
                }

                let magnification = Float(value.magnification)

                let rawScale = state.startScale * magnification

                let clampedScale = SIMD3<Float>(
                    max(minScale, min(rawScale.x, maxScale)),
                    max(minScale, min(rawScale.y, maxScale)),
                    max(minScale, min(rawScale.z, maxScale))
                )

                entity.scale = clampedScale
                state.lastScale = clampedScale
                entity.gestureStateComponent = state

                scene.gizmoController.updateGizmoTransform()

                if gc.typeJewelry == .band {
                    scene.bandOrientation = entity.orientation(relativeTo: nil)
                }
            }
            .onEnded { value in
                guard let entity = value.entity.gestureTarget() else {
                    return
                }

                var state = entity.gestureStateComponent

                guard state.isScaling else {
                    return
                }

                state.lastScale = entity.scale
                state.isScaling = false
                entity.gestureStateComponent = state

                if tutorial.currentStep == .scaleGesture {
                    tutorial.reportUserAction(.scaled)
                }

                editViewModel.markDirty()
                TransformSession.shared.end(entity)
            }
    }
}
