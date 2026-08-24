//
//  SceneSnapshotPhoto.swift
//  CustomJewelryDesigner
//
//  Created by Ni Komang Ayu Juliana on 23/08/26.
//
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

        if let environment = await makeStudioEnvironmentResource() {
            let iblSource = Entity()
            iblSource.components.set(
                ImageBasedLightComponent(source: .single(environment), intensityExponent: 1.5)
            )
            renderer.entities.append(iblSource)
            sceneClone.components.set(ImageBasedLightReceiverComponent(imageBasedLight: iblSource))
        } else {
            print("SceneSnapshotService: continuing without IBL — colors may look flat")
        }

        let camera = PerspectiveCamera()
        camera.camera.near = 0.001
        camera.camera.far = 10
        sceneClone.addChild(camera)
        renderer.entities.append(camera)
        renderer.activeCamera = camera


        let keyLight = DirectionalLight()
        keyLight.light.intensity = 3000
        keyLight.orientation = simd_quatf(angle: -.pi / 3, axis: SIMD3<Float>(1, 0, 0))
        sceneClone.addChild(keyLight)

        let fillLight = PointLight()
        fillLight.light.intensity = 4000
        fillLight.position = SIMD3<Float>(0, 0.2, 0.3)
        sceneClone.addChild(fillLight)


        let rimLight = PointLight()
        rimLight.light.intensity = 3500
        rimLight.position = SIMD3<Float>(0, 0.15, -0.3)
        sceneClone.addChild(rimLight)

        let orbitLight = PointLight()
        orbitLight.light.intensity = 3000
        camera.addChild(orbitLight)

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


        func snapshot(yaw: Float) async -> Data? {
            let orientation = simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))
            camera.position = orientation.act(SIMD3<Float>(0, 0, distance))
            camera.look(at: .zero, from: camera.position, relativeTo: sceneClone)

            do {
                let outputDescriptor = RealityRenderer.CameraOutput.Descriptor.singleProjection(
                    colorTexture: colorTexture
                )
                let cameraOutput = try RealityRenderer.CameraOutput(outputDescriptor)

                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    do {
                        try renderer.updateAndRender(
                            deltaTime: 1.0 / 60.0,
                            cameraOutput: cameraOutput,
                            onComplete: { _ in continuation.resume() }
                        )
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }

                guard let texture = cameraOutput.colorTextures.first else { return nil }
                guard let ciImage = CIImage(
                    mtlTexture: texture,
                    options: [.colorSpace: CGColorSpaceCreateDeviceRGB()]
                )?.oriented(.downMirrored) else { return nil }
                guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }
                return UIImage(cgImage: cgImage).pngData()
            } catch {
                print("SceneSnapshotService: render failed for yaw \(yaw): \(error)")
                return nil
            }
        }

        let front = await snapshot(yaw: 0)
        let back = await snapshot(yaw: .pi)
        let left = await snapshot(yaw: -.pi / 2)
        let right = await snapshot(yaw: .pi / 2)

        return CapturedAngles(front: front, back: back, left: left, right: right)
    }

    private static func makeStudioEnvironmentResource() async -> EnvironmentResource? {
        let width = 512
        let height = 256

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let rendererImg = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)

        let uiImage = rendererImg.image { ctx in
            let colors = [
                UIColor(white: 0.85, alpha: 1.0).cgColor,
                UIColor(white: 0.55, alpha: 1.0).cgColor,
                UIColor(white: 0.22, alpha: 1.0).cgColor
            ] as CFArray

            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0.0, 0.55, 1.0]
            ) else { return }

            ctx.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: height),
                options: []
            )

 
            let softboxSpots: [(xFraction: CGFloat, yFraction: CGFloat, radius: CGFloat)] = [
                (0.15, 0.30, 90),
                (0.65, 0.25, 70),
                (0.40, 0.75, 60)
            ]

            for spot in softboxSpots {
                let center = CGPoint(x: spot.xFraction * CGFloat(width), y: spot.yFraction * CGFloat(height))
                guard let highlightGradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [
                        UIColor(white: 1.0, alpha: 0.9).cgColor,
                        UIColor(white: 1.0, alpha: 0.0).cgColor
                    ] as CFArray,
                    locations: [0.0, 1.0]
                ) else { continue }

                ctx.cgContext.drawRadialGradient(
                    highlightGradient,
                    startCenter: center, startRadius: 0,
                    endCenter: center, endRadius: spot.radius,
                    options: []
                )
            }
        }

        guard let cgImage = uiImage.cgImage else { return nil }

        do {
            return try await EnvironmentResource(equirectangular: cgImage, withName: "StudioGradient")
        } catch {
            print("SceneSnapshotService: failed to generate environment resource: \(error)")
            return nil
        }
    }
}
