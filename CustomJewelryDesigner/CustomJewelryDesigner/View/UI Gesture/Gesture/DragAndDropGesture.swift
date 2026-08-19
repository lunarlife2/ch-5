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
    let editViewModel: EditViewModel
    let scene: JewelrySceneController

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .targetedToAnyEntity()
            .onChanged { value in
                guard let entity = value.entity.gestureTarget() else { return }

                var state = entity.gestureStateComponent

                if state.activeGesture == .none {
                    guard touchTracker.activeTouchCount == 1 else {
                        return
                    }

                    guard let gc = entity.components[GestureComponent.self],
                          gc.canDrag else {
                        return
                    }

                    guard GestureLock.shared.tryClaim(entity, gesture: .drag) else {
                        return
                    }

                    guard state.startDragging() else {
                        GestureLock.shared.release(entity, gesture: .drag)
                        return
                    }

                    if SnappingService.isAttached(entity) {
                        SnappingService.detach(gem: entity, backTo: scene.gemAnchor)
                        scene.gizmoController.updateGizmoTransform()
                    }

                    state.dragStartPoint = entity.position(relativeTo: nil)

                    guard let startLocation = value.unproject(
                        \.startLocation,
                        to: .scene
                    ) else {
                        state.endGesture()
                        entity.gestureStateComponent = state
                        GestureLock.shared.release(entity, gesture: .drag)
                        return
                    }

                    state.dragStartLocation = startLocation
                    state.dragOffset =
                        state.dragStartPoint - state.dragStartLocation
                }

                guard state.activeGesture == .drag else {
                    return
                }

                guard touchTracker.activeTouchCount == 1 else {
                    state.endGesture()
                    entity.gestureStateComponent = state
                    GestureLock.shared.release(entity, gesture: .drag)
                    return
                }

                let globalLocation = value.location

                guard scene.isInsideEditorFrame(globalLocation) else {
                    entity.gestureStateComponent = state
                    return
                }
                guard let currentLocation = value.unproject(
                    \.location,
                    to: .scene
                ) else {
                    entity.gestureStateComponent = state
                    return
                }

                let newWorldPosition =
                    currentLocation + state.dragOffset

                if let parent = entity.parent {
                    entity.position = parent.convert(
                        position: newWorldPosition,
                        from: nil
                    )
                } else {
                    entity.position = newWorldPosition
                }

                scene.gizmoController.updateGizmoTransform()
                entity.gestureStateComponent = state
            }
            .onEnded { value in
                guard let entity = value.entity.gestureTarget() else {
                    return
                }

                var state = entity.gestureStateComponent

                guard state.activeGesture == .drag else {
                    return
                }

                editViewModel.markDirty()

                let finalWorldPosition = entity.position(relativeTo: nil)
                let globalPoint = value.location

                if editViewModel.isOverTrash(globalPoint) {
                    print("drag end", entity.name)

                    editViewModel.requestDelete(for: entity)

                    state.lastPositionDrag = finalWorldPosition
                    state.endGesture()
                    entity.gestureStateComponent = state

                    GestureLock.shared.release(
                        entity,
                        gesture: .drag
                    )

                    return
                }

                if let realityContent = scene.realityContent {

                    let localPoint = scene.localPoint(
                        fromGlobal: globalPoint
                    )

                    let snapPoints = scene.allSnapPoints()

                    if let snapTarget = SnappingService.nearestSnapForDrag(
                        gem: entity,
                        fingerLocal: localPoint,
                        snapPoints: snapPoints,
                        realityContent: realityContent,
                        maxScreenDistance: SnappingService.defaultDragScreenRadius
                    ) {
                        SnappingService.attach(gem: entity, to: snapTarget)
                        
                        scene.gizmoController.updateGizmoTransform()

                    } else {
                        state.lastPositionDrag = finalWorldPosition
                    }

                } else {
                    state.lastPositionDrag = finalWorldPosition
                }

                state.lastPositionDrag = entity.position(relativeTo: nil)

                state.endGesture()
                entity.gestureStateComponent = state

                GestureLock.shared.release(
                    entity,
                    gesture: .drag
                )
            }
    }
}
