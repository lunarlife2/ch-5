//
//  Item.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import Foundation
import SwiftData

@Model
final class DesignFolder {
	@Attribute(.unique) var id: UUID
	var name: String
	@Relationship(deleteRule: .nullify, inverse: \DesignFile.folder) var designs: [DesignFile] = []

	init(id: UUID, name: String) {
		self.id = id
		self.name = name
	}
}

@Model
final class DesignFile {
	@Attribute(.unique) var id: UUID
	var name: String
	var createdAt: Date
	var updatedAt: Date
	var ringPosition: RingPosition

	enum RingPosition: String, Codable, CaseIterable {
		case left, right
	}

	@Attribute(.externalStorage)
	var thumbnailData: Data?

	@Relationship(deleteRule: .cascade)
	var design: Design?
	
	var folder: DesignFolder?

	init(
		id: UUID,
		name: String,
		updatedAt: Date,
		ringPosition: RingPosition,
		design: Design?
	) {
		self.id = id
		self.name = name
		self.createdAt = .now
		self.updatedAt = updatedAt
		self.ringPosition = ringPosition
		self.design = design
		self.folder = nil
	}
}

@Model
final class Design {
	var materialPreset: String

	@Relationship(deleteRule: .cascade, inverse: \BandComponent.design)
	var band: BandComponent?

	@Relationship(deleteRule: .cascade, inverse: \GemComponent.design)
	var gems: [GemComponent] = []

	// optional inverse, useful if you ever need to go Design -> DesignFile
	@Relationship(inverse: \DesignFile.design)
	var file: DesignFile?

	init(
		materialPreset: String,
		band: BandComponent? = nil,
		gems: [GemComponent]
	) {
		self.materialPreset = materialPreset
		self.band = band
		self.gems = gems
	}
}

@Model
final class BandComponent {
	var libraryAssetID: UUID  // FK to Supabase band asset
	var assetStoragePath: String  // cached, so no extra Supabase round-trip
	var name: String
	var style: String?  // e.g. "Twist", "Plain"
	var design: Design?

	init(
		libraryAssetID: UUID,
		assetStoragePath: String,
		name: String,
		style: String? = nil
	) {
		self.libraryAssetID = libraryAssetID
		self.assetStoragePath = assetStoragePath
		self.name = name
		self.style = style
	}
}

@Model
final class GemComponent {
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

	init(
		libraryAssetID: UUID,
		assetStoragePath: String,
		name: String,
		cut: String? = nil,
		caratWeight: Double? = nil,
		color: String? = nil,
		position: SIMD3<Float>? = nil
	) {
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
			guard let x = positionX, let y = positionY, let z = positionZ else {
				return nil
			}
			return SIMD3<Float>(Float(x), Float(y), Float(z))
		}
		set {
			positionX = newValue.map { Double($0.x) }
			positionY = newValue.map { Double($0.y) }
			positionZ = newValue.map { Double($0.z) }
		}
	}
}
