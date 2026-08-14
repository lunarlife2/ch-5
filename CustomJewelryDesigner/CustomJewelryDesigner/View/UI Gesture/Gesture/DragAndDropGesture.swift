//
//  DragAndDropGesture.swift
//  tesJewelryDesign
//
//  Created by Yimei Winata on 06/08/26.
//

import SwiftUI
import RealityKit

struct DragAndDropGesture {
    let touchTracker: TouchCountViewModel
 
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .targetedToAnyEntity()
            .onChanged { value in
                guard let entity = value.entity.gestureTarget() else { return }
 
                var state = entity.gestureStateComponent
 
                if state.activeGesture == .none {
                    guard touchTracker.activeTouchCount == 1 else {
                        print("[GESTURE] fingers:\(touchTracker.activeTouchCount) target:\(entity.name) classified:NONE reason:drag-requires-1-finger")
                        return
                    }
 
                    guard let gc = entity.components[GestureComponent.self], gc.canDrag else { return }
 
                    guard GestureLock.shared.tryClaim(entity, gesture: .drag) else { return }
                    guard state.startDragging() else {
                        GestureLock.shared.release(entity, gesture: .drag)
                        return
                    }
 
                    state.dragStartPoint = entity.position(relativeTo: nil)
                    guard let startLocation = value.unproject(\.startLocation, to: .scene) else {
                        state.endGesture()
                        entity.gestureStateComponent = state
                        GestureLock.shared.release(entity, gesture: .drag)
                        return
                    }
                    state.dragStartLocation = startLocation
                    state.dragOffset = state.dragStartPoint - state.dragStartLocation
                    print("[GESTURE] fingers:1 target:\(entity.name) classified:DRAG lock:acquired state:drag")
                }
 
                guard state.activeGesture == .drag else { return }
 
                guard touchTracker.activeTouchCount == 1 else {
                    print("[GESTURE] fingers:\(touchTracker.activeTouchCount) target:\(entity.name) ABORT drag reason:finger-count-changed")
                    state.endGesture()
                    entity.gestureStateComponent = state
                    GestureLock.shared.release(entity, gesture: .drag)
                    return
                }
 
                guard let currentLocation = value.unproject(\.location, to: .scene) else {
                    entity.gestureStateComponent = state
                    return
                }
 
                let newWorldPosition = currentLocation + state.dragOffset
                if let parent = entity.parent {
                    entity.position = parent.convert(position: newWorldPosition, from: nil)
                } else {
                    entity.position = newWorldPosition
                }
                entity.gestureStateComponent = state
            }
            .onEnded { value in
                guard let entity = value.entity.gestureTarget() else { return }
                var state = entity.gestureStateComponent
                guard state.activeGesture == .drag else { return }
                
                state.lastPositionDrag = entity.position(relativeTo: nil)
                state.endGesture()
                entity.gestureStateComponent = state
                GestureLock.shared.release(entity, gesture: .drag)
//                print("[GESTURE] TOUCH END target:\(entity.name) classified:DRAG lock:released")
            }
    }
}
 
