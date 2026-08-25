//
//  HomeCard.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import SwiftUI

struct HomeCard: View {
	var preview: Image
	var title: String
	var updatedAt: Date
	var isSelecting: Bool
	var isSelected: Bool

	var body: some View {
		VStack(alignment: .leading) {
			ZStack(alignment: .topTrailing) {
				Rectangle()
					.fill(Color.preview)
					.frame(width: 160, height: 160)
					.cornerRadius(10)
				
				preview
					.resizable()
					.scaledToFill()
					.clipped()
					.frame(width: 160, height: 160)
					.cornerRadius(10)

				if isSelecting {
					Image(
						systemName: isSelected
							? "checkmark.circle.fill" : "circle"
					)
					.font(.system(size: 22))
					.foregroundStyle(
						isSelected ? Color.black : Color.black.opacity(0.5)
					)
					.padding(8)
				}
			}
			.padding(.bottom, 20)
			//.shadow(radius: 5)
			Text(title)
				.font(.system(size: 12, weight: .semibold))
				.padding(.bottom, 5)
			Text(
				updatedAt.formatted(
					.dateTime.month(.abbreviated).day(.twoDigits).year()
				)
			)
			.font(.system(size: 10, weight: .regular))
		}
		.frame(width: 160)
		//.background(Color.gray)
	}
}

#Preview {
	HomeCard(
		preview: Image(.detail34),
		title: "test my collection",
		updatedAt: .now, isSelecting: true, isSelected: true
	)
}
