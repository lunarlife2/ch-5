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
    var bandStyleID: BandStyle
    var bandThickness: String
    var bandMaterial : String
    
    enum CodingKeys: String, CodingKey {
        case id = "band_id"
        case assetId = "asset_id"
        case description = "description"
        case bandStyleID = "band_style_id"
        case bandThickness = "band_thickness"
        case bandMaterial = "band_material"
    }
}
