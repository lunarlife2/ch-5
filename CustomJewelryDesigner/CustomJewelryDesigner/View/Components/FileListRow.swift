//
//  FileListRow.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 23/08/26.
//

import SwiftUI

struct FileListRow: View {
	var preview: Image
	var title: String
	var updatedAt: Date
	var isSelecting: Bool
	var isSelected: Bool
	
	enum ListColumns {
		static let thumbnail: CGFloat = 60
		static let name: CGFloat = 200
		// "Last Updated" and "Share" split the remaining space
	}

	var body: some View {
		HStack(spacing: 16) {
			if isSelecting {
				Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
					.font(.system(size: 18))
					.foregroundStyle(isSelected ? Color.black : Color.black.opacity(0.5))
			}

			preview
				.resizable()
				.scaledToFill()
				.frame(width: ListColumns.thumbnail, height: ListColumns.thumbnail)
				.clipShape(RoundedRectangle(cornerRadius: 8))

			Text(title)
				.font(.system(size: 16, weight: .semibold))
				.foregroundStyle(Color.black)
				.frame(width: ListColumns.name, alignment: .leading)

			Text(updatedAtText)
				.font(.system(size: 14))
				.foregroundStyle(.secondary)
				.frame(maxWidth: .infinity, alignment: .center)

			Button {
				// share action
			} label: {
				Image(systemName: "square.and.arrow.up")
					.foregroundStyle(Color.black)
			}
			.buttonStyle(.plain)
			.frame(width: 60, alignment: .trailing)
		}
		.padding(.horizontal, 20)
		.padding(.vertical, 20)
		.contentShape(Rectangle())
	}

	private var updatedAtText: String {
		if Calendar.current.isDateInToday(updatedAt) {
			return "You edited · Today, \(updatedAt.formatted(.dateTime.hour().minute()))"
		} else if Calendar.current.isDateInYesterday(updatedAt) {
			return "You edited · Yesterday, \(updatedAt.formatted(.dateTime.hour().minute()))"
		} else {
			return "You edited · \(updatedAt.formatted(.dateTime.month(.abbreviated).day()))"
		}
	}
}

#Preview {
	List {
		FileListRow(
			preview: Image(.detail34),
			title: "Engagement Ring",
			updatedAt: .now,
			isSelecting: false,
			isSelected: false
		)
		FileListRow(
			preview: Image(.detail34),
			title: "Engagement Ring",
			updatedAt: .now,
			isSelecting: true,
			isSelected: true
		)
	}
}
