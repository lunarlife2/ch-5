//
//  Stone.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 11/08/26.
//


import Foundation

struct Gem: Codable {
  var id: UUID
  var gemShape: String
  var gemMaterial: String
  var assetId: Asset3D
	
	enum CodingKeys: String, CodingKey {
		case id = "gem_id"
		case gemShape = "gem_shape"
        case gemMaterial = "gem_material"
		case assetId = "asset_id"
	}
}
