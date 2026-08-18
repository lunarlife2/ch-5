//
//  GestureLock.swift
//  tesJewelryDesign
//
//  Created by Yimei Winata on 07/08/26.
//

import RealityKit

final class GestureLock {

    static let shared = GestureLock()

    private init() {}

    private(set) var activeEntity: Entity?
    private(set) var activeGesture: ActiveGesture?

    @discardableResult
    func tryClaim(_ entity: Entity, gesture: ActiveGesture) -> Bool {

        if activeEntity == nil {

            activeEntity = entity
            activeGesture = gesture

            return true
        }

        guard activeEntity === entity else {
            return false
        }

        guard activeGesture == gesture else {
            return false
        }

        return true
    }

    func release(_ entity: Entity, gesture: ActiveGesture) {

        guard activeEntity === entity else {
            return
        }

        guard activeGesture == gesture else {
            return
        }
        activeEntity = nil
        activeGesture = nil
    }

    func forceRelease() {

        if let entity = activeEntity {
            print("forse release", entity.name)
        }

        activeEntity = nil
        activeGesture = nil
    }

    func isLocked(_ entity: Entity, by gesture: ActiveGesture? = nil) -> Bool {
        guard activeEntity === entity else {
            return false
        }

        if let gesture {
            return activeGesture == gesture
        }

        return true
    }
}
