//
//  RotationGesture.swift
//  tesJewelryDesign
//
//  Created by Yimei Winata on 06/08/26.
//

//DONT NEED THIS ANYMORE
//AS REFERENCE
//USE TWO FINGER TRANSFORM GESTURE

import Foundation
import RealityKit
import SwiftUI

struct RingRotationGesture {
    
    let touchTracker: TouchCountViewModel
    
    var rotateGesture: some Gesture {
        
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .targetedToAnyEntity()
            .onChanged { value in
                
                guard let entity = value.entity.gestureTarget() else {
                    return
                }
                
                guard touchTracker.activeTouchCount == 2 else {
                    return
                }
                
                guard let gc = entity.components[GestureComponent.self],
                      gc.canRotate
                else {
                    return
                }
                
                var state = entity.gestureStateComponent
                
                if !state.isRotating {
                    guard TransformSession.shared.begin(entity) else {
                        return
                    }
                    state = entity.gestureStateComponent
                    state.isRotating = true
                    state.startOrientationRotate = entity.orientation
                    entity.gestureStateComponent = state
                    print("[GESTURE] START ROTATE", entity.name)
                }
                
                guard state.activeGesture == .transform else {
                    return
                }
                
                let deltaX = Float(value.location.x - value.startLocation.x)
                
                let deltaY = Float(value.location.y - value.startLocation.y)
                print("[ROTATE] DRAG EVENT", "fingers:", touchTracker.activeTouchCount, "dx:", deltaX, "dy:", deltaY)
                
//                let rotationMagnitude = sqrt(deltaX * deltaX + deltaY * deltaY)
                
                let sensitivity: Float = 0.01
                
                let rotationY = deltaX * sensitivity
                
                let rotationX = deltaY * sensitivity
                
                let quaternionY = simd_quatf(angle: rotationY, axis: SIMD3<Float>(0, 1, 0))
                
                let quaternionX = simd_quatf(angle: rotationX, axis: SIMD3<Float>(1, 0, 0))
                
                entity.orientation = quaternionY * quaternionX * state.startOrientationRotate
            }
        
            .onEnded { value in
                guard let entity = value.entity.gestureTarget() else {
                    return
                }
                
                var state = entity.gestureStateComponent
                
                guard state.isRotating else {
                    return
                }
                
                state.isRotating = false
                
                entity.gestureStateComponent = state
                
                TransformSession.shared.end(entity)
                
                print("[GESTURE] TOUCH END", "target:\(entity.name)", "channel:ROTATE")
            }
    }
}
