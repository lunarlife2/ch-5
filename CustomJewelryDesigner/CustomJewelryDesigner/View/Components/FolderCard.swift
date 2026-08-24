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
                    .fill(Color(.systemGray6))
					.frame(width: 140, height: 140)
					.rotationEffect(Angle(degrees: -10))
				preview
					.resizable()
					.scaledToFill()
					.clipped()
					.frame(width: 140, height: 140)
					.cornerRadius(10)
					.padding(.bottom, 20)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

			}
			
			Text(title)
				.font(.system(size: 12, weight: .semibold))
		}
		.frame(width: 160)
	}
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
