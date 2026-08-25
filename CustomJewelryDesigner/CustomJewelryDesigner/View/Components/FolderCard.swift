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
					.fill(Color.folder)
					.rotationEffect(.degrees(-10))
					.frame(width: 140, height: 140)
				Rectangle()
					.fill(Color.preview)
					.frame(width: 140, height: 140)
					.cornerRadius(10)
					.padding(.bottom, 20)
					.offset(y: 10)

				preview
					.resizable()
					.scaledToFill()
					.clipped()
					.frame(width: 140, height: 140)
					.cornerRadius(10)
					.padding(.bottom, 20)
					.offset(y: 10)

			}
			.padding(.bottom, 20)
			
			Text(title)
				.font(.system(size: 12, weight: .semibold))
				.padding(.bottom, 5)
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
