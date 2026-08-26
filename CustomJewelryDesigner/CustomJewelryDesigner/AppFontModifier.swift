//
//  AppFontModifier.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 26/08/26.
//

import SwiftUI

extension Font {
	static func appFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
		.custom(postScriptName(for: weight), size: size)
	}

	private static func postScriptName(for weight: Font.Weight) -> String {
		switch weight {
		case .bold, .heavy, .black:
			return "SpaceMono-Bold"
		case .semibold:
			return "SpaceMono-Regular"
		case .medium:
			return "SpaceMono-Regular"
		case .light, .thin, .ultraLight:
			return "SpaceMono-Regular"
		default:
			return "SpaceMono-Regular"
		}
	}
}
