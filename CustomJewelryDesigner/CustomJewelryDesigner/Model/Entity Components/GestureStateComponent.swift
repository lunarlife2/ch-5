//
//  GestureStateComponent.swift
//  tesJewelryDesign
//
//  Created by Yimei Winata on 07/08/26.
//

import SwiftUI
import RealityKit

public enum ActiveGesture {
    case none
    case drag
    case transform
}

public struct GestureStateComponent: Component {

    public var activeGesture: ActiveGesture = .none

    public var lastPositionDrag: SIMD3<Float> = .zero
    public var lastScale: SIMD3<Float> = .one

    public var lastRotate = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))

    public var cumulativeRotationX: Float = 0
    public var cumulativeRotationY: Float = 0

    public var isDragging = false

    public var dragStartPoint: SIMD3<Float> = .zero
    public var dragStartLocation: SIMD3<Float> = .zero
    public var dragOffset: SIMD3<Float> = .zero

    public var isScaling = false
    public var startScale: SIMD3<Float> = .one

    public var isRotating = false

    public var dragStartAngle: Float = 0

    public var startOrientationRotate = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))

    public var isTransforming = false

    mutating func startDragging() -> Bool {
        guard activeGesture == .none else {
            return false
        }

        activeGesture = .drag
        isDragging = true
        isTransforming = false

        return true
    }

    mutating func startTransform() -> Bool {
        guard activeGesture == .none else {
            return false
        }

        activeGesture = .transform
        isTransforming = true
        isDragging = false

        return true
    }

    mutating func endGesture() {

        lastPositionDrag = dragStartLocation

        activeGesture = .none

        isDragging = false
        isScaling = false
        isRotating = false
        isTransforming = false
    }
}
