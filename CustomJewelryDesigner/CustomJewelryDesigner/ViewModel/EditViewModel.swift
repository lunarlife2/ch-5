//
//  EditViewModel.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//
import Foundation
import SwiftUI
import RealityKit

enum JewelryEditorMode: String, CaseIterable, Identifiable {
    case band
    case handMannequin
    
    var id: String {
        rawValue
    }
    
    var title: String {
        switch self {
        case .band:
            return "Ring View"
        case .handMannequin:
            return "Hand View"
        }
    }
    
    var image: String {
        switch self {
        case .band:
            return "ring_view"
        case .handMannequin:
            return "hand.raised"
        }
    }
    
    var isSystemImage: Bool {
        switch self {
        case .band:
            return false
        case .handMannequin:
            return true
        }
    }
}

@Observable
final class EditViewModel {
    private(set) var _mode: JewelryEditorMode = .band
    
    var mode: JewelryEditorMode {
        get {
            _mode
        }
        set {
            _mode = newValue
            updateVisibility()
        }
    }
    
    let rootEntity = Entity()
    
    let bandPivot = Entity()
    let bandAnchor = Entity()
    
    let gemAnchor = Entity()
    
    let mannequinAnchor = Entity()
    let mannequinPivot = Entity()
    
    let camera = Entity()
    
    var band: Entity {
        bandAnchor
    }
    var selectedGem: Entity {
        gemAnchor
    }
    var mannequin: Entity {
        mannequinAnchor
    }
    var rotationY: Float = 0
    var rotationX: Float = 0
    var isDraggingGem = false
    var scale: Float = 1
    
    private var isSetup = false
    
    private var realityContent: RealityViewCameraContent?
    
    func setRealityContent(_ content: RealityViewCameraContent) {
        realityContent = content
    }
    
    func entityAtScreenLocation(_ location: CGPoint) -> Entity? {
        guard let realityContent else {
            return nil
        }

        let hitEntity = realityContent.entity( at: location, in: .local)

        guard let hitEntity else {
            return nil
        }

        return hitEntity.gestureTarget()
    }
    
    
    func setup() async {
        guard !isSetup else {
            return
        }
        isSetup = true
        
        await loadBand()
        await loadMannequin()
        
        //band
        bandPivot.addChild(bandAnchor)
        rootEntity.addChild(bandPivot)
        
        //mannequin
        mannequinPivot.addChild(mannequinAnchor)
        rootEntity.addChild(mannequinPivot)
        
        //gem
        rootEntity.addChild(gemAnchor)
        
        updateVisibility()
    }
    
    func save() {
        //save edit
    }
    
    func delete(){
        //delete edit
    }
    
    private func updateVisibility() {
        bandPivot.isEnabled = mode == .band
        mannequinPivot.isEnabled = mode == .handMannequin
    }
    
    private func loadBand() async {
        do {
            //load
            let plainBand = try await Entity(named: "Flat_Band_Ring")
            //size
            let plainBandSize = plainBand.visualBounds(relativeTo: nil).extents
            let targetBandDiameter: Float = 0.004
            //scale
            plainBand.scale = .init(repeating:targetBandDiameter / max(plainBandSize.x,plainBandSize.y))
            plainBand.position = [-0.001, 0, 0]
            //band input
            plainBand.generateCollisionShapes(recursive: true)
            plainBand.components.set(InputTargetComponent())
            plainBand.components.set(GestureComponent(typeJewelry: .band, canDrag: false, canScale: true, canRotate: true))
            
            //hierarchy
            bandAnchor.addChild(plainBand)
        }
        catch {
            print("Failed to load band entity", error)
        }
    }
    
    private func loadMannequin() async {
        do {
            //load
            let mannequin = try await Entity(named: "Simplified_Hand_For_Artists")
            //size
            let mannequinSize = mannequin.visualBounds(relativeTo: nil).extents
            let targetMannequinDiameter: Float = 0.008
            //scale
            mannequin.scale = .init(repeating:targetMannequinDiameter / max(mannequinSize.x,mannequinSize.y))
            mannequin.position = [0, -0.5, 0]
            //mannequin input
            mannequin.generateCollisionShapes(recursive: true, static: true)
            mannequin.components.set(InputTargetComponent())
            mannequin.components.set(GestureComponent(typeJewelry: .handMannequin, canDrag: false, canScale: true, canRotate: true))
            
            //hierarchy
            mannequinAnchor.addChild(mannequin)
        }
        catch {
            print("Failed to load entity", error)
        }
    }
    
    public func addStone(screenLocation: CGPoint? = nil, containerSize: CGSize? = nil) async {
        print("Stone Added")
        
        do {
            let gemstone = try await Entity(named: "Gemstone")
            
            let gemstoneSize = gemstone.visualBounds(relativeTo: nil).extents
            let targetGemstoneDiameter: Float = 0.004
            //scale
            gemstone.scale = .init(repeating:targetGemstoneDiameter / max(gemstoneSize.x,gemstoneSize.y))
            
            gemstone.name = "Gemstone"
            
            if let loc = screenLocation, let size = containerSize {
                let nx = Float(loc.x / size.width) - 0.5
                let nz = Float(loc.y / size.height) - 0.5
                gemstone.position = [nx * 0.02, 1, nz * 0.02]
            } else {
                gemstone.position = [0, 1, 0]
            }
            
            gemstone.generateCollisionShapes(recursive: true)
            gemstone.components.set(InputTargetComponent())
            gemstone.components.set(GestureComponent(typeJewelry: .gemstone, canDrag: true, canScale: true, canRotate: true))
            
            gemAnchor.addChild(gemstone)
            
            print("Gem parent:", gemstone.parent?.name ?? "nil")
            print("Gem position:", gemstone.position)
            print("Gem anchor children:", gemAnchor.children.count)
        }
        catch {
            print("Failed to load entity", error)
        }
    }
    
    func handleDrop(identifier: String, screenLocation: CGPoint? = nil, containerSize: CGSize? = nil) async {
        switch identifier {
        case "Flat_Band_Ring":
            await replaceBand()
        case "Gemstone":
            await addStone(screenLocation: screenLocation, containerSize: containerSize)
        default:
            print("Unknown drop identifier:", identifier)
        }
    }
    
    private func replaceBand() async {
        bandAnchor.children.removeAll()
        await loadBand()
    }
    
    
    
}
