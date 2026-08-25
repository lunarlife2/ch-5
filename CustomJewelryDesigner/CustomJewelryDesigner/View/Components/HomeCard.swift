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
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(width: 160, height: 160)

                preview
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if isSelecting {
                    Image(
                        systemName: isSelected
                            ? "checkmark.circle.fill" : "circle"
                    )
                    .font(.system(size: 22))
                    .foregroundStyle(
                        isSelected ? Color.appPrimary : Color.white
                    )
                    .background(
                        Circle()
                            .fill(isSelected ? Color.white : Color.black.opacity(0.25))
                            .frame(width: 22, height: 22)
                    )
                    .padding(8)
                }
            }
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
            .padding(.bottom, 12)

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .padding(.bottom, 4)
            Text(
                updatedAt.formatted(
                    .dateTime.month(.abbreviated).day(.twoDigits).year()
                )
            )
            .font(.system(size: 10, weight: .regular))
            .foregroundStyle(.secondary)
        }
        .frame(width: 160)
    }
}

#Preview {
	HomeCard(
		preview: Image(.detail34),
		title: "test my collection",
		updatedAt: .now, isSelecting: true, isSelected: true
	)
}
