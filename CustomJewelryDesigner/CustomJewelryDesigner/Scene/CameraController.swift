//
//  CameraController.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 18/08/26.
//

import Foundation
import RealityKit
import simd

@MainActor
final class CameraController {

    let pivot = Entity()
    let camera = PerspectiveCamera()

    private(set) var yaw: Float = 0
    private(set) var pitch: Float = 0
    private(set) var distance: Float = 0.6

    var orbitSensitivity: Float = 0.01

    var minimumDistance: Float = 0.15
    var maximumDistance: Float = 3.0
    var pitchLimit: Float = .pi / 2 - 0.05

    init() {
        pivot.addChild(camera)

        camera.position = SIMD3<Float>(
            0,
            0,
            distance
        )

        updateCameraOrientation()
    }

    func orbit(
        deltaX: Float,
        deltaY: Float
    ) {
        yaw -= deltaX * orbitSensitivity
        pitch -= deltaY * orbitSensitivity

        pitch = max(
            -pitchLimit,
            min(pitchLimit, pitch)
        )

        updateCameraOrientation()
    }

    func zoom(delta: Float) {
        distance += delta

        distance = max(
            minimumDistance,
            min(maximumDistance, distance)
        )

        camera.position.z = distance
    }

    private func updateCameraOrientation() {

        let yawRotation = simd_quatf(
            angle: yaw,
            axis: SIMD3<Float>(0, 1, 0)
        )

        let pitchRotation = simd_quatf(
            angle: pitch,
            axis: SIMD3<Float>(1, 0, 0)
        )

        pivot.orientation =
            yawRotation * pitchRotation
    }

    func reset() {
        yaw = 0
        pitch = 0
        distance = 0.6

        camera.position.z = distance

        updateCameraOrientation()
    }

    func setView(axis: ViewAxis) {

        switch axis {

        case .x:
            lookAlongX()

        case .negativeX:
            lookAlongNegativeX()

        case .y:
            lookAlongY()

        case .negativeY:
            lookAlongNegativeY()

        case .z:
            lookAlongZ()

        case .negativeZ:
            lookAlongNegativeZ()
        }
    }

    func lookAlongX() {
        yaw = -.pi / 2
        pitch = 0
        updateCameraOrientation()
    }

    func lookAlongNegativeX() {
        yaw = .pi / 2
        pitch = 0
        updateCameraOrientation()
    }

    func lookAlongY() {
        yaw = 0
        pitch = -.pi / 2
        updateCameraOrientation()
    }

    func lookAlongNegativeY() {
        yaw = 0
        pitch = .pi / 2
        updateCameraOrientation()
    }

    func lookAlongZ() {
        yaw = 0
        pitch = 0
        updateCameraOrientation()
    }

    func lookAlongNegativeZ() {
        yaw = .pi
        pitch = 0
        updateCameraOrientation()
    }
}

