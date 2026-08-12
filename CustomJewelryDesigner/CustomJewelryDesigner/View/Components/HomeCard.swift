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
	
	var body: some View {
		VStack(alignment: .leading) {
			preview
				.resizable()
				.scaledToFill()
				.clipped()
				.frame(width: 160, height: 160)
				.cornerRadius(10)
				.shadow(radius: 5)
			Text(title)
				.font(.title)
			Text("Last Modified at \(updatedAt.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year(.extended())))")
		}
		.frame(width: 160)
		//.background(Color.gray)
	}
}

#Preview {
	HomeCard(preview: Image(.detail34), title: "test", updatedAt: .now)
}
