//
//  MagnifyingGesture.swift
//  tesJewelryDesign
//
//  Created by Yimei Winata on 06/08/26.
//

//DONT NEED THIS ANYMORE
//AS REFERENCE
//USE TWO FINGER TRANSFORM GESTURE

import SwiftUI
import RealityKit

struct MagnifyingGesture {
    let touchTracker: TouchCountViewModel
 
    var zoomGesture: some Gesture {
        MagnifyGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                guard let entity = value.entity.gestureTarget() else { return }
 
                guard touchTracker.activeTouchCount == 2 else {
//                    print("[GESTURE] fingers:\(touchTracker.activeTouchCount) target:\(entity.name) ABORT scale reason:finger-count-changed")
                    TransformSession.shared.forceEndIfStuck()
                    return
                }
 
                guard let gc = entity.components[GestureComponent.self], gc.canScale else { return }
 
                var state = entity.gestureStateComponent
                if !state.isScaling {
                    guard TransformSession.shared.begin(entity) else { return }
                    state = entity.gestureStateComponent
                    state.isScaling = true
                    state.startScale = entity.scale
                    entity.gestureStateComponent = state
                }
                entity.scale = state.startScale * Float(value.magnification)
            }
            .onEnded { value in
                guard let entity = value.entity.gestureTarget() else { return }
                var state = entity.gestureStateComponent
                state.isScaling = false
                entity.gestureStateComponent = state
                TransformSession.shared.end(entity)
//                print("[GESTURE] TOUCH END target:\(entity.name) channel:SCALE")
            }
    }
}
 
 
