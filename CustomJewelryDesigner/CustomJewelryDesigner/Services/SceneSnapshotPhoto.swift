//
//  SceneSnapshotPhoto.swift
//  CustomJewelryDesigner
//
//  Created by Ni Komang Ayu Juliana on 23/08/26.
//

import Foundation
import RealityKit
import Metal
import CoreImage
import UIKit
import simd

@MainActor
enum SceneSnapshotService {

    struct CapturedAngles {
        var front: Data?
        var back: Data?
        var left: Data?
        var right: Data?
    }

    static func captureAngles(
        rootEntity: Entity,
        distance: Float = 0.35,
        imageSize: CGSize = CGSize(width: 600, height: 600)
    ) async -> CapturedAngles {
        guard let renderer = try? await RealityRenderer() else {
            print("SceneSnapshotService: failed to create RealityRenderer")
            return CapturedAngles()
        }

        let sceneClone = rootEntity.clone(recursive: true)
        renderer.entities.append(sceneClone)

        let camera = PerspectiveCamera()
        camera.camera.near = 0.001
        camera.camera.far = 10
        sceneClone.addChild(camera)
        renderer.entities.append(camera)
        renderer.activeCamera = camera

        let keyLight = DirectionalLight()
        keyLight.light.intensity = 3500
        keyLight.orientation = simd_quatf(angle: -.pi / 3, axis: SIMD3<Float>(1, 0, 0))
        sceneClone.addChild(keyLight)

        let fillLight = PointLight()
        fillLight.light.intensity = 6000
        fillLight.position = SIMD3<Float>(0, 0.2, 0.3)
        sceneClone.addChild(fillLight)

        guard let device = MTLCreateSystemDefaultDevice() else {
            print("SceneSnapshotService: no Metal device available")
            return CapturedAngles()
        }

        let width = Int(imageSize.width)
        let height = Int(imageSize.height)

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = [.renderTarget, .shaderRead]

        guard let colorTexture = device.makeTexture(descriptor: textureDescriptor) else {
            print("SceneSnapshotService: failed to create color texture")
            return CapturedAngles()
        }

        let ciContext = CIContext(mtlDevice: device)

        func snapshot(yaw: Float) -> Data? {
            let orientation = simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))
            camera.position = orientation.act(SIMD3<Float>(0, 0, distance))
            camera.look(at: .zero, from: camera.position, relativeTo: sceneClone)

            do {
                let outputDescriptor = RealityRenderer.CameraOutput.Descriptor.singleProjection(
                    colorTexture: colorTexture
                )
                let cameraOutput = try RealityRenderer.CameraOutput(outputDescriptor)

                var resultData: Data?
                try renderer.updateAndRender(
                    deltaTime: 1.0 / 60.0,
                    cameraOutput: cameraOutput
                ) { _ in
                    guard let texture = cameraOutput.colorTextures.first else { return }
                    guard let ciImage = CIImage(
                        mtlTexture: texture,
                        options: [.colorSpace: CGColorSpaceCreateDeviceRGB()]
                    )?.oriented(.downMirrored) else { return }
                    guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
                    resultData = UIImage(cgImage: cgImage).pngData()
                }
                return resultData
            } catch {
                print("SceneSnapshotService: render failed for yaw \(yaw): \(error)")
                return nil
            }
        }

        let front = snapshot(yaw: 0)
        let back = snapshot(yaw: .pi)
        let left = snapshot(yaw: -.pi / 2)
        let right = snapshot(yaw: .pi / 2)

        return CapturedAngles(front: front, back: back, left: left, right: right)
    }
}
