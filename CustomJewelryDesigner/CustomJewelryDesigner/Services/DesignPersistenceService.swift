//
//  DesignPersistenceService.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 17/08/26.
//

import Foundation
import SwiftData
import RealityKit

struct DesignPersistenceService {

    func save(gemEntities: [Entity], bandEntity: Entity?, bandPivot: Entity, pendingBandAssetPath: String, pendingBandName: String, ringSizeID: Int?, ringSizeSystem: RingSizeSystem?, designFile: DesignFile, design: Design, modelContext: ModelContext) throws {

        for gemEntity in gemEntities {
            let worldPosition = gemEntity.position(relativeTo: nil)
            let worldOrientation = gemEntity.orientation(relativeTo: nil)

            let worldScale = Double(gemEntity.scale(relativeTo: nil).x)
            let attachedSnapID = gemEntity.components[AttachmentComponent.self]?.attachedSnapID

            if let existing = design.gems.first(where: { $0.name == gemEntity.name }) {
                existing.position = worldPosition
                existing.orientation = worldOrientation
                existing.scaleFactor = worldScale
                existing.attachedSnapPointID = attachedSnapID
            } else {
                let newComponent = GemComponent(libraryAssetID: UUID(), assetStoragePath: "Gemstone", name: gemEntity.name, position: worldPosition)

                newComponent.orientation = worldOrientation
                newComponent.scaleFactor = worldScale
                newComponent.attachedSnapPointID = attachedSnapID
                newComponent.design = design
                design.gems.append(newComponent)
                modelContext.insert(newComponent)
            }
        }
        
        if let bandEntity {
            if let bandComponent = design.band {
                bandComponent.orientation = bandEntity.orientation(relativeTo: bandPivot)
                bandComponent.scaleFactor = Double(bandEntity.scale.x)
                bandComponent.assetStoragePath = pendingBandAssetPath

                bandComponent.name = pendingBandName
            } else {
                let newBandComponent = BandComponent(libraryAssetID: UUID(), assetStoragePath: pendingBandAssetPath, name: pendingBandName)

                newBandComponent.orientation = bandEntity.orientation(relativeTo: bandPivot)

                newBandComponent.scaleFactor = Double(bandEntity.scale.x)
                newBandComponent.design = design
                design.band = newBandComponent
                modelContext.insert(newBandComponent)
            }
        }
        designFile.updatedAt = .now
        design.ringSizeID = ringSizeID
        design.ringSizeSystem = ringSizeSystem
        try modelContext.save()
    }
    
    func delete(gemName: String, from design: Design, modelContext: ModelContext) {
        guard let existing = design.gems.first(where: { $0.name == gemName }) else {
            return
        }
        modelContext.delete(existing)
        design.gems.removeAll { $0.name == gemName }
    }
}
