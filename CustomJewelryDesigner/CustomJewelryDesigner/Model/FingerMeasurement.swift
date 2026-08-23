//
//  FingerMeasurement.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 23/08/26.
//

import Foundation
import SwiftData

@Model
final class FingerMeasurement {
    @Attribute(.unique) var handFingerRawValue: String
    var ringSizeID: Int
    var ringSizeSystemRawValue: String
    var diameterMM: Double
    var updatedAt: Date

    init(
        handFinger: HandFinger,
        ringSizeID: Int,
        ringSizeSystem: RingSizeSystem,
        diameterMM: Double
    ) {
        self.handFingerRawValue = handFinger.rawValue
        self.ringSizeID = ringSizeID
        self.ringSizeSystemRawValue = ringSizeSystem.rawValue
        self.diameterMM = diameterMM
        self.updatedAt = .now
    }

    var handFinger: HandFinger {
        HandFinger(rawValue: handFingerRawValue) ?? .rightthumb
    }

    var ringSizeSystem: RingSizeSystem {
        RingSizeSystem(rawValue: ringSizeSystemRawValue) ?? .usCanada
    }

    var ringSizeOption: RingSizeOption? {
        ringSizeOptions.first { $0.id == ringSizeID }
    }

    var displaySize: String {
        ringSizeOption?.size(for: ringSizeSystem) ?? "–"
    }
}
