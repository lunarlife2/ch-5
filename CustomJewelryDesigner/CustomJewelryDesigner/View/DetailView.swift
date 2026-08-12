//
//  DetailView.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import SwiftUI
import SwiftData

struct DetailView: View {
	@Environment(\.modelContext) private var modelContext
	//@Query private var designFile: DesignFile
	
	@State private var notes: String = ""
	@State private var size: Double = 13.5
	@State private var showPopUp: Bool = false
	@State private var ringSizesGuide = ringSizes
	let columnsCount = 4

	var body: some View {
		ZStack {
			HStack {
				VStack {
					Image(.detail34)
						.padding()
					HStack {
						Image(.detailTop)
						Image(.detailBottom)
						Image(.detailLeft)
						Image(.detailRight)
					}
				}
				.padding()
				.background(Color.red.opacity(0.2))

				VStack(alignment: .leading) {
					Text("File name ")
						.font(.title)
					Text("Date")
						.font(.headline)
					Text("Metal")
						.font(.title3)
					Text("Gem")
					Text("Thickness")
					HStack {
						Text(
							"Ring Size: \(size, format: .number.precision(.fractionLength(1)))"
						)
						.font(.headline)

						Spacer()

						Button {
							showPopUp.toggle()
						} label: {
							Image(systemName: "questionmark.circle")
						}
					}

					Slider(value: $size, in: 3...15.5, step: 0.5)
						.tint(.blue)  // Changes the active track color
					Text("Notes")
					TextField(
						"Type your notes here",
						text: $notes,
						axis: .vertical
					)
					.textFieldStyle(.roundedBorder)
					.lineLimit(3...6)
					.frame(alignment: .top)

					HStack(spacing: 10) {
						Button {
							//go back to edit view
						} label: {
							Text("Back")
								.frame(maxWidth: .infinity)
						}
						.buttonStyle(.glass)
						.tint(Color.black)

						//Spacer()

						Button {
							//save data
							//go to home
						} label: {
							Text("Save")
								.frame(maxWidth: .infinity)
						}
						.buttonStyle(.glassProminent)
						.tint(Color.cyan)
					}
					.padding()
				}
				.padding()
				.background(Color.red.opacity(0.2))
			}

			if !showPopUp {
				VStack {

					Text("Ring Size Guide")
						.font(.title)
						.padding()

					ForEach(ringSizesGuide) { ringSize in

							Text(ringSize.size)
								.padding()
								.background(Color.blue.opacity(0.2))
								.cornerRadius(8)

					}

				}
				.background(
					RoundedRectangle(cornerRadius: 10).foregroundColor(.white)
				)

			}

		}
		.padding()
		.background(Color.secondary)
	}
}

#Preview {
	DetailView()
}
