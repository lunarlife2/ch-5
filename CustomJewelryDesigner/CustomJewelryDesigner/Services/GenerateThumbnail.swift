////
////  GenerateThumbnail.swift
////  CustomJewelryDesigner
////
////  Created by Averina on 13/08/26.
////
//
//import RealityKit
//import UIKit
//
//@MainActor
//func generateThumbnail(for design: DesignFile, size: CGSize = CGSize(width: 300, height: 300)) async -> Data? {
//	do {
//		let renderer = try RealityRenderer()
//
//		// Build a scene root and add your existing entities
//		let root = Entity()
//		renderer.entities.append(root)
//
//		let bandEntity = await makeEntity(from: design.bandComponent) // your existing loading logic
//		let gemEntity = await makeEntity(from: design.gemComponent)
//		root.addChild(bandEntity)
//		root.addChild(gemEntity)
//
//		// Camera
//		let camera = PerspectiveCamera()
//		camera.position = [0, 0.1, 0.3]
//		camera.look(at: .zero, from: camera.position, relativeTo: nil)
//		root.addChild(camera)
//		renderer.activeCamera = camera
//
//		// Light
//		let light = DirectionalLight()
//		light.light.intensity = 2000
//		root.addChild(light)
//
//		// Render to CGImage
//		var cgImage: CGImage?
//		try renderer.render(
//			destination: .image(descriptor: .init(size: SIMD2(Int(size.width), Int(size.height))))
//		) { image in
//			cgImage = image
//		}
//
//		guard let cgImage else { return nil }
//		return UIImage(cgImage: cgImage).pngData()
//	} catch {
//		print("Thumbnail render failed: \(error)")
//		return nil
//	}
//}
