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
					.fill(Color.white)
					.frame(width: 160, height: 160)
									
				preview
					.resizable()
					.scaledToFill()
					.clipped()
					.frame(width: 160, height: 160)
					.border(Color.black)

                if isSelecting {
                    Image(
                        systemName: isSelected
                            ? "checkmark.circle.fill" : "circle"
                    )
                    .font(.appFont(size: 22))
                    .foregroundStyle(
                        isSelected ? Color.appPrimary : Color.black
                    )
                    .background(
                        Circle()
                            .fill(isSelected ? Color.white : Color.clear)
                            .frame(width: 22, height: 22)
                    )
                    .padding(8)
                }
            }
            .padding(.bottom, 12)

            Text(title)
                .font(.appFont(size: 12, weight: .semibold))
                .padding(.bottom, 4)
            Text(
                updatedAt.formatted(
                    .dateTime.month(.abbreviated).day(.twoDigits).year()
                )
            )
            .font(.appFont(size: 10, weight: .regular))
            .foregroundStyle(.secondary)
        }
        .frame(width: 160)
    }
}

#Preview {
	HomeCard(
		preview: Image(.detail34),
		title: "test my collection",
		updatedAt: .now, isSelecting: true, isSelected: false
	)
}
