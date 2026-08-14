//
//  TwoFingerTransformGesture.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 13/08/26.
//
import UIKit
import RealityKit
import SwiftUI
import Foundation

struct TwoFingerTransformGesture: UIGestureRecognizerRepresentable {

    typealias UIGestureRecognizerType = TwoFingerTransformRecognizer

    let touchTracker: TouchCountViewModel

    let entityProvider: (CGPoint) -> Entity?

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        weak var targetEntity: Entity?
        var startScale: SIMD3<Float> = .one
        var startOrientation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
        var classification: TransformClassification = .undetermined
    }


    func makeUIGestureRecognizer(context: Context) -> TwoFingerTransformRecognizer {
        let recognizer = TwoFingerTransformRecognizer()
        recognizer.cancelsTouchesInView = false
        return recognizer
    }


    func updateUIGestureRecognizer(_ recognizer: TwoFingerTransformRecognizer, context: Context) {
        // No dynamic UIKit configuration required.
    }

    func handleUIGestureRecognizerAction(_ recognizer: TwoFingerTransformRecognizer, context: Context) {
        switch recognizer.state {
        case .began:
            handleBegan(recognizer, context: context)

        case .changed:
            handleChanged(recognizer, context: context)

        case .ended:
            handleEnded(recognizer, context: context)

        case .cancelled,
             .failed:
            handleCancelledOrFailed(recognizer, context: context)

        default:
            break
        }
    }


    private func handleBegan(_ recognizer: TwoFingerTransformRecognizer, context: Context) {
        guard recognizer.numberOfTouches == 2 else {
            return
        }
        guard touchTracker.activeTouchCount == 2 else {
//            print("[2F] BEGIN IGNORED", "tracker:", touchTracker.activeTouchCount)
            recognizer.state = .failed
            return
        }

        let localPoint = context.converter.localLocation

        guard let entity = entityProvider(localPoint) else {
//            print("[2F] BEGIN FAILED", "reason:no-target", "point:", localPoint)
            recognizer.state = .failed
            return
        }

        guard let gc = entity.components[GestureComponent.self] else {
//            print("[2F] BEGIN FAILED", "reason:no-GestureComponent", "entity:", entity.name)
            recognizer.state = .failed
            return
        }

        guard gc.canScale || gc.canRotate else {
//            print("[2F] BEGIN FAILED", "reason:no-transform-capability", "entity:", entity.name)
            recognizer.state = .failed
            return
        }

        guard TransformSession.shared.begin(entity) else {
//            print("[2F] BEGIN FAILED", "reason:transform-lock", "entity:", entity.name)
            recognizer.state = .failed
            return
        }

        context.coordinator.targetEntity = entity

        context.coordinator.startScale = entity.scale

        context.coordinator.startOrientation = entity.orientation

        context.coordinator.classification = .undetermined

//        print("[2F] BEGIN", "target:", entity.name, "distance:", recognizer.currentDistance)
    }


    private func handleChanged(_ recognizer: TwoFingerTransformRecognizer, context: Context) {
        guard recognizer.numberOfTouches == 2 else {
            return
        }
        guard touchTracker.activeTouchCount == 2 else {

//            print("[2F] ABORT", "reason:finger-count-changed")
            if let entity = context.coordinator.targetEntity {
                TransformSession.shared.end(entity)
            }

            context.coordinator.targetEntity = nil
            return
        }

        guard let entity = context.coordinator.targetEntity else {
            return
        }

        guard let gc = entity.components[GestureComponent.self] else {
            return
        }

        let panX = Float(recognizer.panDelta.x)

        let panY = Float(recognizer.panDelta.y)

        let panMagnitude = sqrt(panX * panX + panY * panY)

        let scaleMagnitude = Float(abs(recognizer.scaleDelta))

        let classification = TransformSession.shared.classify(panMagnitude: panMagnitude, scaleMagnitude: scaleMagnitude)

        context.coordinator.classification = classification

        guard classification != .undetermined else {
            return
        }

        switch classification {

        case .rotate:
            guard gc.canRotate else {
                return
            }
            applyRotation(entity: entity,recognizer: recognizer, coordinator: context.coordinator)

        case .scale:
            guard gc.canScale else {
                return
            }
            applyScale(entity: entity, recognizer: recognizer, coordinator: context.coordinator)

        case .undetermined:
            break
        }
    }


    private func applyRotation(entity: Entity, recognizer: TwoFingerTransformRecognizer, coordinator: Coordinator) {
        var state = entity.gestureStateComponent

        state.isRotating = true
        state.isScaling = false

        let deltaX = Float(recognizer.panDelta.x)

        let deltaY = Float(recognizer.panDelta.y)
        
        let rotationY = deltaX * 0.01

        let rotationX = deltaY * 0.01

        let quaternionY = simd_quatf(angle: rotationY, axis: SIMD3<Float>(0, 1, 0))

        let quaternionX = simd_quatf(angle: rotationX, axis: SIMD3<Float>(1, 0, 0))

        entity.orientation = quaternionY * quaternionX * coordinator.startOrientation

        entity.gestureStateComponent = state

        print("[2F] ROTATE", "target:", entity.name, "dx:", deltaX, "dy:", deltaY)
    }

    private func applyScale(entity: Entity, recognizer: TwoFingerTransformRecognizer, coordinator: Coordinator) {
        var state = entity.gestureStateComponent

        state.isScaling = true
        state.isRotating = false
        
        guard recognizer.currentDistance > 0, recognizer.numberOfTouches == 2 else {
            return
        }

        let startDistance = recognizer.currentDistance - recognizer.scaleDelta

        guard startDistance > 0 else {
            return
        }

        let magnification = Float(recognizer.currentDistance / startDistance)

        let clampedMagnification = max(0.05, min(magnification, 20.0))

        entity.scale = coordinator.startScale * clampedMagnification

        entity.gestureStateComponent = state

//        print("[2F] SCALE", "target:", entity.name, "distance:", recognizer.currentDistance, "magnification:", clampedMagnification)
    }


    private func handleEnded(_ recognizer: TwoFingerTransformRecognizer, context: Context) {

        guard let entity = context.coordinator.targetEntity else {
            return
        }

//        print("[2F] END", "target:", entity.name, "classification:", context.coordinator.classification)

        var state = entity.gestureStateComponent
        state.lastRotate = entity.orientation
        state.lastScale = entity.scale
        
        if context.coordinator.classification == .rotate {
            let dx = Float(recognizer.panDelta.x)
            let dy = Float(recognizer.panDelta.y)
            state.cumulativeRotationX += dx * 0.01
            state.cumulativeRotationY += dy * 0.01
        }
        
        TransformSession.shared.end(entity)

        context.coordinator.targetEntity = nil
        context.coordinator.classification = .undetermined
    }


    private func handleCancelledOrFailed(_ recognizer: TwoFingerTransformRecognizer, context: Context) {

        guard let entity = context.coordinator.targetEntity else {
            return
        }

        print("[2F] CANCEL/FAIL", "target:", entity.name, "classification:", context.coordinator.classification)

        TransformSession.shared.end(entity)

        context.coordinator.targetEntity = nil
        context.coordinator.classification = .undetermined
    }
}
