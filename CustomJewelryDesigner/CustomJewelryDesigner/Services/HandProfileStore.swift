//
//  HandProfileStore.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 23/08/26.
//

import Foundation
import SwiftData

struct HandProfileStore {
    let modelContext: ModelContext

    func measurement(for handFinger: HandFinger) -> FingerMeasurement? {
        let raw = handFinger.rawValue
        let descriptor = FetchDescriptor<FingerMeasurement>(
            predicate: #Predicate { $0.handFingerRawValue == raw }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func allMeasurements() -> [FingerMeasurement] {
        let descriptor = FetchDescriptor<FingerMeasurement>(
            sortBy: [SortDescriptor(\.handFingerRawValue)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    @discardableResult
    func save(
        handFinger: HandFinger,
        ringSizeID: Int,
        system: RingSizeSystem,
        diameterMM: Double
    ) -> FingerMeasurement {
        if let existing = measurement(for: handFinger) {
            existing.ringSizeID = ringSizeID
            existing.ringSizeSystemRawValue = system.rawValue
            existing.diameterMM = diameterMM
            existing.updatedAt = .now
            try? modelContext.save()
            return existing
        } else {
            let new = FingerMeasurement(
                handFinger: handFinger,
                ringSizeID: ringSizeID,
                ringSizeSystem: system,
                diameterMM: diameterMM
            )
            modelContext.insert(new)
            try? modelContext.save()
            return new
        }
    }
}
