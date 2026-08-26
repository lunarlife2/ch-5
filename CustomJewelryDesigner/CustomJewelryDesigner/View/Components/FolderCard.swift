//
//  FolderCard.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 15/08/26.
//

import SwiftUI

struct FolderCard: View {
	var preview: Image
	var title: String

	var body: some View {
		VStack(alignment: .leading) {
			ZStack{
				Rectangle()
					.fill(Color.white)
					.frame(width: 150, height: 150)
					.border(Color.black, width: 1)
				
				Rectangle()
					.fill(Color.white)
					.frame(width: 150, height: 150)
					.border(Color.black, width: 1)
					.offset(x: -10, y: 10)

				preview
					.resizable()
					.scaledToFill()
					.clipped()
					.frame(width: 150, height: 150)
					.border(Color.black, width: 1)
					.offset(x: -10, y: 10)

			}
			.padding(.bottom, 20)
			.frame(maxWidth: .infinity, alignment: .trailing)
			
			Text(title)
				.font(.appFont(size: 12, weight: .semibold))
				.padding(.bottom, 5)
				.textCase(.uppercase)
		}
		.frame(width: 160)
	}
}

#Preview {
	FolderCard(
		preview: Image(.detail34),
		title: "test my collection",
	)
}


extension Image {
	init(thumbnailData: Data?, placeholder: String = "photo") {
		if let thumbnailData, let uiImage = UIImage(data: thumbnailData) {
			self = Image(uiImage: uiImage)
		} else {
			self = Image(systemName: placeholder)
		}
	}
}
