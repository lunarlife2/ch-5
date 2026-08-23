//
//  RingSizerViewModel.swift
//  CustomJewelryDesigner
//
//  Created by Ni Komang Ayu Juliana on 12/08/26.
//

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
final class RingSizerViewModel {

    var pointsPerMM: CGFloat
    var separationPoints: CGFloat = 0
    var ringSizeSystem: RingSizeSystem

    init(pointsPerMM: CGFloat, ringSizeSystem: RingSizeSystem) {
        self.pointsPerMM = pointsPerMM
        self.ringSizeSystem = ringSizeSystem
        self.separationPoints = 0
    }

    var availableOptions: [RingSizeOption] {
        ringSizeOptions.filter { $0.size(for: ringSizeSystem) != nil }
    }

    var minSeparation: CGFloat {
        guard let first = availableOptions.first else { return 0 }
        return CGFloat(first.diameterMM) * pointsPerMM
    }

    var maxSeparation: CGFloat {
        guard let last = availableOptions.last else { return 0 }
        return CGFloat(last.diameterMM) * pointsPerMM
    }

    var diameterMM: Double {
        guard pointsPerMM > 0 else { return 0 }
        return Double(separationPoints / pointsPerMM)
    }

    var closestRingSize: RingSizeOption? {
        guard !availableOptions.isEmpty else { return nil }
        return availableOptions.min {
            abs($0.diameterMM - diameterMM) < abs($1.diameterMM - diameterMM)
        }
    }

    func reset() {
        separationPoints = (minSeparation + maxSeparation) / 2
    }

    func setSeparation(_ value: CGFloat) {
        separationPoints = min(max(value, minSeparation), maxSeparation)
    }
}
