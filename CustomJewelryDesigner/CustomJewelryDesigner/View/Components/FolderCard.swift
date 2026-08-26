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
			ZStack(alignment: .bottom){
				Rectangle()
					.fill(Color.white)
					.frame(width: 140, height: 140)
					.border(Color.black, width: 1)
					.offset(x: 10, y: -10)
				
				Rectangle()
					.fill(Color.white)
					.frame(width: 140, height: 140)
					.border(Color.black, width: 1)

				preview
					.resizable()
					.scaledToFill()
					.clipped()
					.frame(width: 140, height: 140)
					.border(Color.black, width: 1)

			}
			.padding(.bottom, 20)
			
			Text(title)
				.font(.appFont(size: 12, weight: .semibold))
				.padding(.bottom, 5)
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
