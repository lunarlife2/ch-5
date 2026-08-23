//
//  GenerateThumbnail.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 13/08/26.
//

import RealityKit
import Metal
import CoreImage
import UIKit

enum ThumbnailAngle: String, CaseIterable {
	case front, back, right, left

	var cameraPosition: SIMD3<Float> {
		switch self {
		case .front: return [0, 0.05, 0.3]
		case .back:  return [0, 0.05, -0.3]
		case .right: return [0.3, 0.05, 0]
		case .left:  return [-0.3, 0.05, 0]
		}
	}
}

@MainActor
func generateThumbnails(
	bandEntity: Entity?,
	gemEntities: [Entity],
	angles: [ThumbnailAngle] = ThumbnailAngle.allCases,
	size: Int = 300
) async -> [ThumbnailAngle: Data] {
	do {
		let renderer = try RealityRenderer()

		let root = Entity()
		if let bandEntity {
			root.addChild(bandEntity.clone(recursive: true))
		}
		for gemEntity in gemEntities {
			root.addChild(gemEntity.clone(recursive: true))
		}
		renderer.entities.append(root)

		let camera = PerspectiveCamera()
		renderer.entities.append(camera)
		renderer.activeCamera = camera

		let light = DirectionalLight()
		light.light.intensity = 2000
		light.look(at: .zero, from: [0.3, 0.5, 0.3], relativeTo: nil)
		renderer.entities.append(light)

		guard let device = MTLCreateSystemDefaultDevice() else { return [:] }

		let textureDescriptor = MTLTextureDescriptor()
		textureDescriptor.pixelFormat = .rgba8Unorm
		textureDescriptor.width = size
		textureDescriptor.height = size
		textureDescriptor.usage = [.renderTarget, .shaderRead]

		guard let colorTexture = device.makeTexture(descriptor: textureDescriptor) else { return [:] }

		let outputDescriptor = RealityRenderer.CameraOutput.Descriptor.singleProjection(colorTexture: colorTexture)
		let cameraOutput = try RealityRenderer.CameraOutput(outputDescriptor)

		var results: [ThumbnailAngle: Data] = [:]

		for angle in angles {
			camera.position = angle.cameraPosition
			camera.look(at: .zero, from: angle.cameraPosition, relativeTo: nil)

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

			if let data = imageData(from: colorTexture) {
				results[angle] = data
			}
		}

		return results
	} catch {
		print("Multi-angle thumbnail render failed: \(error)")
		return [:]
	}
}

private func imageData(from texture: MTLTexture) -> Data? {
	guard let ciImage = CIImage(mtlTexture: texture, options: [.colorSpace: CGColorSpaceCreateDeviceRGB()])?
		.oriented(.downMirrored),
		  let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
		return nil
	}
	return UIImage(cgImage: cgImage).pngData()
}
