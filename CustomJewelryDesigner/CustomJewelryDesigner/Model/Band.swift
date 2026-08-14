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
    var material: String
    
    enum CodingKeys: String, CodingKey {
        case id = "band_id"
        case assetId = "asset_id"
        case description = "description"
        case material = "material"
        case bandStyleID = "band_style_id"
    }
}
