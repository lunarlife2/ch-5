//
//  BandGemViewModel.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 14/08/26.
//

import Foundation

//switch view between band, gem, and size
enum BandGemSize: String, CaseIterable, Identifiable {
    case band
    case gem
    case size
    
    var id: String {
        rawValue
    }
    
    var image: String {
        switch self {
        case .band:
            return "circle"
        case .gem:
            return "diamond"
        case .size:
            return "hand.point.up"
        }
    }
    
    var title: String {
        switch self {
        case .band:
            return "Band"
        case .gem:
            return "Gem"
        case .size:
            return "Size"
        }
    }
}

//band style
enum BandStyleEnum: String, CaseIterable, Identifiable {
    case classic
    case flat
    case knifeEdge
    case twisted
    
    var id: String {
        rawValue
    }
    
    var title: String {
        switch self {
        case .classic:
            return "Classic"
        case .flat:
            return "Flat"
        case .knifeEdge:
            return "Knife Edge"
        case .twisted:
            return "Twisted"
        }
    }
}
//band material
enum BandMaterialEnum: String, CaseIterable, Identifiable {
    case yellowGold
    case whiteGold
    case roseGold
    case silver
    
    var id: String {
        rawValue
    }
    
    var title: String {
        switch self {
        case .yellowGold:
            return "Yellow Gold"
        case .whiteGold:
            return "White Gold"
        case .roseGold:
            return "Rose Gold"
        case .silver:
            return "Silver"
        }
    }
}

enum BandThicknessEnum: Int, CaseIterable, Identifiable {
    case thin = 1
    case medium = 2
    case thick = 3
    
    var id: Int {
        rawValue
    }
    
    var title: String {
        switch self {
        case .thin:
            return "Thin"
        case .medium:
            return "Medium"
        case .thick:
            return "Thick"
        }
    }
}

enum GemShapeEnum: String, CaseIterable, Identifiable {
    case round
    case oval
    case princess
    case pear
    
    var id: String {
        rawValue
    }
    
    var title: String {
        switch self {
        case .round:
            return "Thin"
        case .oval:
            return "Medium"
        case .princess:
            return "Thick"
        case .pear:
            return "Pear"
        }
    }
}

enum GemMaterialEnum: String, CaseIterable, Identifiable {
    case diamond
    case ruby
    case sapphire
    case silver
    
    var id: String {
        rawValue
    }
    
    var title: String {
        switch self {
        case .diamond:
            return "Diamond"
        case .ruby:
            return "Ruby"
        case .sapphire:
            return "Sapphire"
        case .silver:
            return "Silver"
        }
    }
}

enum Finger: String, CaseIterable, Identifiable {
    case thumb
    case index
    case middle
    case ring
    case pinky
    
    var id: String {
        rawValue
    }
    
    var title: String {
        switch self {
        case .thumb:
            return "Thumb"
        case .index:
            return "Index"
        case .middle:
            return "Middle"
        case .ring:
            return "Ring"
        case .pinky:
            return "Pinky"
        }
    }
}

enum Hand: String, CaseIterable, Identifiable {
    case right
    case left
    
    var id: String {
        rawValue
    }
    
    var title: String {
        switch self {
        case .right:
            return "Right"
        case .left:
            return "Left"
        }
    }
}

@Observable
final class BandGemViewModel {
    private(set) var _mode: BandGemSize = .band
    
    var mode: BandGemSize {
        get {
            _mode
        }
        set {
            _mode = newValue
        }
    }
    
    var selectedRingSizeSystem: RingSizeSystem = .usCanada
    
    var selectedRingSizeID: Int = 20
    
    var selectedRingSize: RingSizeOption? {
        ringSizeOptions.first {
            $0.id == selectedRingSizeID
        }
    }
}
