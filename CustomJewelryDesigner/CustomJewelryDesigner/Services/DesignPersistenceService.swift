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
    
    func save(gemEntities: [Entity], bandEntity: Entity?, bandAnchor: Entity, ringSizeID: Int?, ringSizeSystem: RingSizeSystem?, finger: Finger, hand: Hand, designFile: DesignFile, design: Design, modelContext: ModelContext) throws {
        
        for gemEntity in gemEntities {
            let worldPosition = gemEntity.position(relativeTo: nil)
            let worldOrientation = gemEntity.orientation(relativeTo: nil)
            let worldScale = Double(gemEntity.scale(relativeTo: nil).x)
            let attachedSnapID = gemEntity.components[AttachmentComponent.self]?.attachedSnapID
            let source = gemEntity.components[GemSourceComponent.self]
            
            if let existing = design.gems.first(where: { $0.name == gemEntity.name }) {
                existing.position = worldPosition
                existing.orientation = worldOrientation
                existing.scaleFactor = worldScale
                existing.attachedSnapPointID = attachedSnapID
            } else {
                let newComponent = GemComponent(
                    libraryAssetID: source?.libraryAssetID ?? UUID(),
                    assetStoragePath: source?.assetStoragePath ?? "Gemstone",
                    name: gemEntity.name,
                    cut: source?.cut,
                    color: source?.color,
                    position: worldPosition
                )
                newComponent.orientation = worldOrientation
                newComponent.scaleFactor = worldScale
                newComponent.attachedSnapPointID = attachedSnapID
                newComponent.design = design
                design.gems.append(newComponent)
                modelContext.insert(newComponent)
            }
        }
        
        if let bandEntity {
            let source = bandEntity.components[BandSourceComponent.self]
            let assetPath = source?.assetStoragePath ?? design.band?.assetStoragePath ?? "Flat_Band_Ring"
            let name = source?.name ?? design.band?.name ?? "plain band usd"
            
            if let bandComponent = design.band {
                bandComponent.orientation = bandAnchor.orientation(relativeTo: nil)
                bandComponent.scaleFactor = Double(bandEntity.scale.x)
                bandComponent.assetStoragePath = assetPath
                bandComponent.name = name
            } else {
                let newBandComponent = BandComponent(
                    libraryAssetID: source?.libraryAssetID ?? UUID(),
                    assetStoragePath: assetPath,
                    name: name
                )
                newBandComponent.orientation = bandAnchor.orientation(relativeTo: nil)
                newBandComponent.scaleFactor = Double(bandEntity.scale.x)
                newBandComponent.design = design
                design.band = newBandComponent
                modelContext.insert(newBandComponent)
            }
        }
        
        designFile.updatedAt = .now
        design.ringSizeID = ringSizeID
        design.ringSizeSystem = ringSizeSystem
        design.finger = finger
        design.hand = hand

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
