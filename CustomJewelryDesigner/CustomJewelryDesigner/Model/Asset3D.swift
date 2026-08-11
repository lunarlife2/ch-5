//
//  3DAsset.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 11/08/26.
//

import Foundation

struct Asset3D: Codable {
  var id: UUID
  var storagePath: String
  var thumbnailPath: String
	
	enum CodingKeys: String, CodingKey {
		case id = "asset_id"
		case storagePath = "storage_path"
		case thumbnailPath = "thumbnail_path"
	}
}
