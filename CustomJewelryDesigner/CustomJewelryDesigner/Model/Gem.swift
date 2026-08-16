//
//  Stone.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 11/08/26.
//


import Foundation

struct Stone: Codable {
  var id: UUID
  var name: String
  var description: String
  var assetId: Asset3D
	
	enum CodingKeys: String, CodingKey {
		case id = "stone_id"
		case name
		case description
		case assetId = "asset_id"
	}
}
