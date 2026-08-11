//
//  Item.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import Foundation
import SwiftData

@Model
class DesignFile {
	var id: UUID
	var name: String
	var createdAt: Date
	var updatedAt: Date
	@Relationship(deleteRule: .cascade) var designs: [Design] = []
	
	init(id: UUID, name: String, createdAt: Date, updatedAt: Date, designs: [Design] = []) {
		self.id = id
		self.name = name
		self.createdAt = createdAt
		self.updatedAt = updatedAt
		self.designs = designs
	}
}

@Model
class Design {
	var id: UUID
	var name: String
	var materialPreset: String
	var createdAt: Date
	var updatedAt: Date

	@Relationship(deleteRule: .cascade, inverse: \BandComponent.design)
	var band: BandComponent?
	
	@Relationship(deleteRule: .cascade, inverse: \GemComponent.design)
	var gems: [GemComponent] = []

	init(id: UUID, name: String, materialPreset: String, createdAt: Date, updatedAt: Date, band: BandComponent? = nil, gems: [GemComponent] = []) {
		self.id = id
		self.name = name
		self.materialPreset = materialPreset
		self.createdAt = createdAt
		self.updatedAt = updatedAt
		self.band = band
		self.gems = gems
	}
}

@Model
class BandComponent {
	var libraryAssetID: UUID          // FK to Supabase band asset
	var assetStoragePath: String      // cached, so no extra Supabase round-trip
	var name: String
	var style: String?                // e.g. "Twist", "Plain"
	var design: Design?
	
	init(libraryAssetID: UUID, assetStoragePath: String, name: String, style: String? = nil) {
		self.libraryAssetID = libraryAssetID
		self.assetStoragePath = assetStoragePath
		self.name = name
		self.style = style
	}
}

@Model
class GemComponent {
	var libraryAssetID: UUID
	var assetStoragePath: String
	var name: String
	var cut: String?
	var caratWeight: Double?
	var color: String?
	var design: Design?

	// Stored as three plain Doubles — SwiftData-safe
	var positionX: Double?
	var positionY: Double?
	var positionZ: Double?

	init(libraryAssetID: UUID, assetStoragePath: String, name: String, cut: String? = nil, caratWeight: Double? = nil, color: String? = nil, position: SIMD3<Float>? = nil) {
		self.libraryAssetID = libraryAssetID
		self.assetStoragePath = assetStoragePath
		self.name = name
		self.cut = cut
		self.caratWeight = caratWeight
		self.color = color
		self.positionX = position.map { Double($0.x) }
		self.positionY = position.map { Double($0.y) }
		self.positionZ = position.map { Double($0.z) }
	}

	// Computed property for use in RealityKit code
	var position: SIMD3<Float>? {
		get {
			guard let x = positionX, let y = positionY, let z = positionZ else { return nil }
			return SIMD3<Float>(Float(x), Float(y), Float(z))
		}
		set {
			positionX = newValue.map { Double($0.x) }
			positionY = newValue.map { Double($0.y) }
			positionZ = newValue.map { Double($0.z) }
		}
	}
}
