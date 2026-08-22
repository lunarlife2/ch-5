//
//  SkinColorPresets.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 22/08/26.
//

import Foundation

struct SkinColorPresets: Identifiable {
    let id: Int
    let color: String
}

let skinColorPresets: [SkinColorPresets] = [
    SkinColorPresets(id: 1, color: "#483326"),
    SkinColorPresets(id: 2, color: "#694833"),
    SkinColorPresets(id: 3, color: "#836045"),
    SkinColorPresets(id: 4, color: "#996C4B"),
    SkinColorPresets(id: 5, color: "#BD8B6E"),
    SkinColorPresets(id: 6, color: "#DDA785"),
    SkinColorPresets(id: 7, color: "#EDBFA2"),
    SkinColorPresets(id: 8, color: "#F4CFB7"),
    SkinColorPresets(id: 9, color: "#F5D8BB")
]
