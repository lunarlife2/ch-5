//
//  BandType.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 11/08/26.
//

import Foundation

struct BandStyle: Codable, Identifiable, Equatable  {
  var id: UUID
  var bandStyleName: String
  var description: String
	
	enum CodingKeys: String, CodingKey {
		case id = "band_style_id"
        case bandStyleName = "band_style_name"
		case description = "band_style_description"
	}
}
