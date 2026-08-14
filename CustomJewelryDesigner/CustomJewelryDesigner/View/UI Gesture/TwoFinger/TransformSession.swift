//
//  TransformSession.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 13/08/26.
//

import RealityKit
import Foundation

enum TransformClassification {
    case undetermined
    case rotate
    case scale
}

final class TransformSession {

    static let shared = TransformSession()

    private init() {}

    private let panDeadZone: Float = 8.0
    private let scaleDeadZone: Float = 8.0
    private let dominanceMargin: Float = 1.20

    private(set) var entity: Entity?
    private(set) var classification: TransformClassification = .undetermined

    private var isActive = false

    @discardableResult
    func begin(_ entity: Entity) -> Bool {

        if isActive {
            return self.entity === entity
        }

        guard GestureLock.shared.tryClaim(entity, gesture: .transform) else {
//            print("[TRANSFORM] BEGIN REJECTED", "entity:", entity.name)
            return false
        }

        var state = entity.gestureStateComponent

        guard state.startTransform() else {
            GestureLock.shared.release(entity, gesture: .transform)
//            print("[TRANSFORM] BEGIN REJECTED", "entity:", entity.name, "reason: entity-already-has-gesture")
            return false
        }

        self.entity = entity
        self.classification = .undetermined
        self.isActive = true

        state.isScaling = false
        state.isRotating = false

        state.startScale = entity.scale
        state.startOrientationRotate = entity.orientation

        entity.gestureStateComponent = state

//        print("[TRANSFORM] BEGIN", "target:", entity.name, "classification:PENDING", "lock:acquired")

        return true
    }


    func classify(panMagnitude: Float, scaleMagnitude: Float) -> TransformClassification {
        guard isActive else {
            return .undetermined
        }

        guard classification == .undetermined else {
            return classification
        }

        let pan = abs(panMagnitude)
        let scale = abs(scaleMagnitude)

        let panReady = pan >= panDeadZone
        let scaleReady = scale >= scaleDeadZone

        let panNorm = pan / panDeadZone

        let scaleNorm = scale / scaleDeadZone

//        print("[TRANSFORM] CLASSIFY", "pan:", pan, "scale:", scale, "panNorm:", panNorm, "scaleNorm:", scaleNorm)

        if !panReady && !scaleReady {
            return .undetermined
        }

        if panReady && !scaleReady {
            classification = .rotate
//            print("[TRANSFORM] CLASSIFIED -> ROTATE", "panNorm:", panNorm, "scaleNorm:", scaleNorm)
            return .rotate
        }

        if scaleReady && !panReady {
            classification = .scale
//            print("[TRANSFORM] CLASSIFIED -> SCALE", "panNorm:", panNorm, "scaleNorm:", scaleNorm)
            return .scale
        }

        if panNorm >= scaleNorm * dominanceMargin {
            classification = .rotate
//            print("[TRANSFORM] CLASSIFIED -> ROTATE", "reason:pan-dominant", "panNorm:", panNorm, "scaleNorm:", scaleNorm)
            return .rotate
        }

        if scaleNorm >= panNorm * dominanceMargin {
            classification = .scale
            print("[TRANSFORM] CLASSIFIED -> SCALE", "reason:scale-dominant", "panNorm:", panNorm, "scaleNorm:", scaleNorm)
            return .scale
        }

        return .undetermined
    }


    func end(_ entity: Entity) {
        guard isActive else {
            return
        }

        guard self.entity === entity else {
            return
        }

        var state = entity.gestureStateComponent

        state.endGesture()

        entity.gestureStateComponent = state

        GestureLock.shared.release(entity, gesture: .transform)

//        print("[TRANSFORM] END", "target:", entity.name, "classification:", classification)

        self.entity = nil
        self.classification = .undetermined
        self.isActive = false
    }


    func forceEndIfStuck() {
        guard let entity else {
            self.classification = .undetermined
            self.isActive = false
            return
        }

        var state = entity.gestureStateComponent

        state.endGesture()

        entity.gestureStateComponent = state

        GestureLock.shared.release(entity, gesture: .transform)

        print("[TRANSFORM] FORCE END", "target:", entity.name)

        self.entity = nil
        self.classification = .undetermined
        self.isActive = false
    }
}

