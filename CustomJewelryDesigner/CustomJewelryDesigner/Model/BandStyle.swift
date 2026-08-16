//
//  BandType.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 11/08/26.
//

import Foundation

struct BandStyle: Codable {
  var id: UUID
  var description: String
  var bandStyleName: UUID
	
	enum CodingKeys: String, CodingKey {
		case id = "band_style_id"
		case description = "description"
		case bandStyleName = "band_type_name"
	}
}
