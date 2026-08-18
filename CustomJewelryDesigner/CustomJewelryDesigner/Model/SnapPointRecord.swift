//
//  SnapPointRecord.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 15/08/26.
//

import Foundation
import SwiftData

@Model
final class SnapPointRecord {
    @Attribute(.unique) var snapID: String
    var index: Int
    var occupiedByGemName: String?
    var band: BandComponent?

    init(snapID: String, index: Int) {
        self.snapID = snapID
        self.index = index
    }
}
