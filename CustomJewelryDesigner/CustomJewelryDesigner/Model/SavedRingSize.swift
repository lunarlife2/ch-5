//
//  SavedRingSize.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 23/08/26.
//

import Foundation
import SwiftData

@Model
final class SavedRingSize {
	// HandFinger.rawValue as the identity — one record per finger, no need
	// to duplicate hand/finger as separate raw-string properties.
	@Attribute(.unique) var handFingerRaw: String = HandFinger.leftpointer.rawValue

	private var systemRaw: String = RingSizeSystem.usCanada.rawValue
	var sizeID: Int = 0
	var updatedAt: Date = Date()

	var handFinger: HandFinger {
		get { HandFinger(rawValue: handFingerRaw) ?? .leftpointer }
		set { handFingerRaw = newValue.rawValue }
	}

	var system: RingSizeSystem {
		get { RingSizeSystem(rawValue: systemRaw) ?? .usCanada }
		set { systemRaw = newValue.rawValue }
	}

	init(handFinger: HandFinger, system: RingSizeSystem, sizeID: Int) {
		self.handFinger = handFinger
		self.system = system
		self.sizeID = sizeID
	}
}
