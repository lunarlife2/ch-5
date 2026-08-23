//
//  DetailView.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import SwiftUI
import SwiftData

struct DetailView: View {
	@Environment(ViewModel.self) private var vm
	@Environment(\.modelContext) private var modelContext
	//@Query private var designFile: DesignFile
//	let designFile: DesignFile
//	
//	@State private var notes: String = ""
//	@State private var size: Double = 13.5
//	@State private var showPopUp: Bool = false
//	@State private var ringSizesGuide = ringSizes
//	let columns = Array(
//			repeating: GridItem(.flexible(minimum: 32, maximum: 100), spacing: 32),
//			count: 4
//		)

	var body: some View {
//		ZStack {
//			HStack {
//				VStack {
//					Image(.detail34)
//						.padding()
//					HStack {
//						Image(.detailTop)
//						Image(.detailBottom)
//						Image(.detailLeft)
//						Image(.detailRight)
//					}
//				}
//				.padding()
//				.background(Color.red.opacity(0.2))
//
//				VStack(alignment: .leading) {
//					Text("File name \(designFile.name)")
//						.font(.title)
//					Text("Date \(designFile.updatedAt)")
//						.font(.headline)
//					Text("Metal \(designFile.name)")
//						.font(.title3)
//					Text("Gem \(designFile.name)")
//					Text("Thickness \(designFile.name)")
//						Text(
//							"Ring Size: \(size, format: .number.precision(.fractionLength(1)))"
//						)
//						.font(.headline)
//
//					Text("Notes")
//					TextField(
//						"Type your notes here",
//						text: $notes,
//						axis: .vertical
//					)
//					.textFieldStyle(.roundedBorder)
//					.lineLimit(3...6)
//					.frame(alignment: .top)
//
//					HStack(spacing: 10) {
//						Button {
//							//balik ke edit view
//						} label: {
//							Text("Back")
//								.frame(maxWidth: .infinity)
//						}
//						.buttonStyle(.glass)
//						.tint(Color.black)
//
//						Button {
//							//save data to swift data
//							vm.moveScreenState(to: .home)
//						} label: {
//							Text("Save")
//								.frame(maxWidth: .infinity)
//						}
//						.buttonStyle(.glassProminent)
//						.tint(Color.cyan)
//					}
//					.padding()
//				}
//				.padding()
//				.background(Color.red.opacity(0.2))
//			}
//
//			if showPopUp {
//				VStack {
//
//					Text("Ring Size Guide")
//						.font(.title)
//						.padding()
//					LazyVGrid(columns: columns, spacing: 32){
//						ForEach(ringSizesGuide) { ringSize in
//							
//							Text(ringSize.size)
//								.padding()
//								.background(Color.blue.opacity(0.2))
//								.cornerRadius(8)
//								.fixedSize(horizontal: true, vertical: false)
//						}
//					}
//					.fixedSize(horizontal: true, vertical: false)
//					.padding()
//				}
//				.background(
//					RoundedRectangle(cornerRadius: 10).foregroundColor(.white)
//				)
//			}
//
//		}
//		.padding()
//		.background(Color.secondary)
	}
}

#Preview {
	DetailView()
}
