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
            return false
        }

        var state = entity.gestureStateComponent

        guard state.startTransform() else {
            GestureLock.shared.release(entity, gesture: .transform)
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
        if !panReady && !scaleReady {
            return .undetermined
        }

        if panReady && !scaleReady {
            classification = .rotate
            return .rotate
        }

        if scaleReady && !panReady {
            classification = .scale
            return .scale
        }

        if panNorm >= scaleNorm * dominanceMargin {
            classification = .rotate
            return .rotate
        }

        if scaleNorm >= panNorm * dominanceMargin {
            classification = .scale
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

        self.entity = nil
        self.classification = .undetermined
        self.isActive = false
    }
}
