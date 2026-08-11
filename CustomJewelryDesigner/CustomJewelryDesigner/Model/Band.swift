//
//  Band.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 11/08/26.
//

import Foundation

struct Band: Codable {
  var id: UUID
  var assetId: Asset3D
  var description: String
  var bandTypeID: BandType
	
	enum CodingKeys: String, CodingKey {
		case id = "band_id"
		case assetId = "asset_id"
		case description = "description"
		case bandTypeID = "band_type_id"
	}
}
