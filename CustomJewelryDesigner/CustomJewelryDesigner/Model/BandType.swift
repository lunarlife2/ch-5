//
//  BandType.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 11/08/26.
//

import Foundation

struct BandType: Codable {
  var id: UUID
  var description: String
  var bandTypeName: UUID
	
	enum CodingKeys: String, CodingKey {
		case id = "band_type_id"
		case description = "description"
		case bandTypeName = "band_type_name"
	}
}
