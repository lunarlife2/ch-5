//
//  Item.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import Foundation
import SwiftData
import RealityKit

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
	var ringPositionRaw: RingPosition?
	
	// what the rest of your app uses — behaves exactly like before
		var ringPosition: RingPosition {
			get { ringPositionRaw ?? .left }
			set { ringPositionRaw = newValue }
		}

	enum RingPosition: String, Codable, CaseIterable {
		case left, right
	}

	@Attribute(.externalStorage)
	var thumbnailData: Data?
	
	// new — detail gallery only
	@Attribute(.externalStorage)
	var backThumbnailData: Data?

	@Attribute(.externalStorage)
	var rightThumbnailData: Data?

	@Attribute(.externalStorage)
	var leftThumbnailData: Data?

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

extension DesignFile {
	var galleryImages: [(label: String, data: Data?)] {
		[
			("Front", thumbnailData),
			("Back", backThumbnailData),
			("Right", rightThumbnailData),
			("Left", leftThumbnailData)
		]
	}
}

@Model
final class Design {
    var materialPreset: String
    
    var ringSizeID: Int?
    var ringSizeSystemRawValue: String?
    
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
        gems: [GemComponent],
        ringSizeID: Int? = nil,
        ringSizeSystem: RingSizeSystem? = nil
        
    ) {
        self.materialPreset = materialPreset
        self.band = band
        self.gems = gems
        self.ringSizeID = ringSizeID
        self.ringSizeSystemRawValue = ringSizeSystem?.rawValue
    }
    
    var ringSizeSystem: RingSizeSystem? {
        get {
            guard let rawValue = ringSizeSystemRawValue else {
                return nil
            }
            return RingSizeSystem(rawValue: rawValue)
        }
        set {
            ringSizeSystemRawValue = newValue?.rawValue
        }
    }
        
    var ringSizeOption: RingSizeOption? {
        guard let ringSizeID else {
            return nil
        }
        
        return ringSizeOptions.first {
            $0.id == ringSizeID
        }
    }
}

@Model
final class BandComponent {
    var libraryAssetID: UUID  // FK to Supabase band asset
    var assetStoragePath: String  // cached, so no extra Supabase round-trip
    var name: String
    var style: String?  // e.g. "Twist", "Plain"
    var design: Design?
    
    var rotationX: Double?
    var rotationY: Double?
    var rotationZ: Double?
    var rotationW: Double?
    var scaleFactor: Double?
    
    @Relationship(deleteRule: .cascade, inverse: \SnapPointRecord.band)
    var snapPoints: [SnapPointRecord] = []
    
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
    
    var orientation: simd_quatf? {
        get {
            guard let x = rotationX, let y = rotationY, let z = rotationZ, let w = rotationW else {
                return nil
            }
            return simd_quatf(ix: Float(x), iy: Float(y), iz: Float(z), r: Float(w))
        }
        set {
            rotationX = newValue.map { Double($0.imag.x) }
            rotationY = newValue.map { Double($0.imag.y) }
            rotationZ = newValue.map { Double($0.imag.z) }
            rotationW = newValue.map { Double($0.real) }
        }
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
    
    var rotationX: Double?
    var rotationY: Double?
    var rotationZ: Double?
    var rotationW: Double?
    var scaleFactor: Double?
    
    var attachedSnapPointID: String?
    
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
    
    var orientation: simd_quatf? {
        get {
            guard let x = rotationX, let y = rotationY, let z = rotationZ, let w = rotationW else {
                return nil
            }
            return simd_quatf(ix: Float(x), iy: Float(y), iz: Float(z), r: Float(w))
        }
        set {
            rotationX = newValue.map { Double($0.imag.x) }
            rotationY = newValue.map { Double($0.imag.y) }
            rotationZ = newValue.map { Double($0.imag.z) }
            rotationW = newValue.map { Double($0.real) }
        }
    }
    
}
