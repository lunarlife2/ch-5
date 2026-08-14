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
 
    func tryClaim(_ entity: Entity, gesture: ActiveGesture) -> Bool {
        if activeEntity == nil {
            activeEntity = entity
            activeGesture = gesture
//            print("[GESTURE] LOCK acquired ->", entity.name, gesture)
            return true
        }
 
        guard activeEntity === entity else {
//            print("[GESTURE] LOCK rejected -> \(entity.name)/\(gesture) held by \(activeEntity?.name ?? "?")/\(activeGesture!)")
            return false
        }
 
        guard activeGesture == gesture else {
//            print("[GESTURE] LOCK rejected -> \(entity.name) wants \(gesture) but holds \(activeGesture!)")
            return false
        }
 
        return true
    }
 
    func release(_ entity: Entity, gesture: ActiveGesture) {
        guard activeEntity === entity, activeGesture == gesture else {
            return
        }
//        print("[GESTURE] LOCK released ->", entity.name, gesture)
        activeEntity = nil
        activeGesture = nil
    }
 
    func forceRelease() {
        if let e = activeEntity {
            print("[GESTURE] LOCK force-released ->", e.name)
        }
        activeEntity = nil
        activeGesture = nil
    }
    
    func cancelDragIfOwnedBy(_ entity: Entity) {
        guard activeEntity === entity else {
            return
        }

        guard activeGesture == .drag else {
            return
        }

//        print("[GESTURE] ABORT DRAG", "entity:", entity.name, "reason: finger-count-changed")

        activeEntity = nil
        activeGesture = nil
    }
}
 
