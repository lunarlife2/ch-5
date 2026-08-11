//
//  Item.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
