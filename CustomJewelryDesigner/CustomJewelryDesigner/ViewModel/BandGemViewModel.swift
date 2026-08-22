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
            return "Round"
        case .oval:
            return "Oval"
        case .princess:
            return "Princess"
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

enum HandFinger: String, CaseIterable, Identifiable {
    case leftthumb
    case leftpointer
    case leftmiddle
    case leftring
    case leftpinky
    
    case rightthumb
    case rightpointer
    case rightmiddle
    case rightring
    case rightpinky
    
    var id: String {
        rawValue
    }
    
    var title: String {
        switch self {
        case .leftthumb:
            return "Left - Thumb"
        case .leftpointer:
            return "Left - Pointer Finger"
        case .leftmiddle:
            return "Left - Middle Finger"
        case .leftring:
            return "Left - Ring Finger"
        case .leftpinky:
            return "Left - Pinky Finger"
        case .rightthumb:
            return "Right - Thumb"
        case .rightpointer:
            return "Right - Pointer Finger"
        case .rightmiddle:
            return "Right - Middle Finger"
        case .rightring:
            return "Right - Ring Finger"
        case .rightpinky:
            return "Right - Pinky Finger"
        }
    }
    
    var hand: Hand {
        rawValue.hasPrefix("left") ? .left : .right
    }
    
    var finger: Finger {
        switch self {
        case .leftthumb, .rightthumb:
            return .thumb
        case .leftpointer, .rightpointer:
            return .index
        case .leftmiddle, .rightmiddle:
            return .middle
        case .leftring, .rightring:
            return .ring
        case .leftpinky, .rightpinky:
            return .pinky
        }
    }
    
    static func from(hand: Hand, finger: Finger) -> HandFinger {
        allCases.first { $0.hand == hand && $0.finger == finger }!
    }
}

@Observable
final class BandGemViewModel {
    private(set) var _mode: BandGemSize = .band
    
    var mode: BandGemSize {
        get { _mode }
        set { _mode = newValue }
    }
    
    var selectedRingSizeSystem: RingSizeSystem = .usCanada
    var selectedRingSizeID: Int = 20
    var selectedRingSize: RingSizeOption? {
        ringSizeOptions.first { $0.id == selectedRingSizeID }
    }
    
    func loadRingSize(id: Int?, system: RingSizeSystem?) {
        if let system {
            selectedRingSizeSystem = system
        }
        guard let id else { return }
        guard let ring = ringSizeOptions.first(where: { $0.id == id }) else { return }
        guard ring.size(for: selectedRingSizeSystem) != nil else { return }
        selectedRingSizeID = id
    }
}
