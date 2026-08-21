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

    private let pointsPerMM: CGFloat

    var separationPoints: CGFloat = 0

    init(pointsPerMM: CGFloat) {
        self.pointsPerMM = pointsPerMM
        self.separationPoints = 0
    }

    var minSeparation: CGFloat {
        guard let first = ringSizeOptions.first else {
            return 0
        }

        return CGFloat(first.diameterMM) * pointsPerMM
    }

    var maxSeparation: CGFloat {
        guard let last = ringSizeOptions.last else {
            return 0
        }

        return CGFloat(last.diameterMM) * pointsPerMM
    }

    var diameterMM: Double {
        guard pointsPerMM > 0 else {
            return 0
        }

        return Double(separationPoints / pointsPerMM)
    }

    var closestRingSize: RingSizeOption? {
        guard !ringSizeOptions.isEmpty else {
            return nil
        }

        return ringSizeOptions.min {
            abs($0.diameterMM - diameterMM)
            <
            abs($1.diameterMM - diameterMM)
        }
    }

    func reset() {
        separationPoints =
            (minSeparation + maxSeparation) / 2
    }

    func setSeparation(_ value: CGFloat) {
        separationPoints = min(
            max(value, minSeparation),
            maxSeparation
        )
    }
}
