//
//  HomeView.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import SwiftData
import SwiftUI

struct HomeView: View {
	@Environment(ViewModel.self) private var vm
	@Environment(\.modelContext) private var modelContext
	@Query(sort: \DesignFile.updatedAt, order: .reverse)
	private var designFiles: [DesignFile]
	let columns = [
		GridItem(
			.adaptive(minimum: 160, maximum: 160),
			spacing: 24,
			alignment: .top
		)
	]

	@State private var isShowing: Bool = false
	@State private var fileName: String = ""

	var body: some View {
		ZStack {
			VStack {
				Text("HomeView")
				ScrollView(.vertical, showsIndicators: true) {
					LazyVGrid(columns: columns, spacing: 32) {
						ForEach(designFiles) { file in
							HomeCard(
								preview: Image(.detail34),
								title: file.name,
								updatedAt: file.updatedAt
							)
						}
					}

				}
				.padding()
				Button("New") {
					isShowing.toggle()
				}
			}

			if isShowing {
				Color.black.opacity(0.4)
					.ignoresSafeArea()
					.onTapGesture { isShowing = false }

				VStack {
					Text("File Name")
						.font(.headline)
					TextField("File name", text: $fileName)
						.textFieldStyle(.roundedBorder)

					Button("Close") {
						isShowing = false
						fileName = ""
					}
					Button("Create") {
						if fileName.isEmpty {
							return
						}
						let store = DesignFileStore(modelContext: modelContext)
						store.createDesignFile(name: fileName)
						isShowing = false
						fileName = ""
						vm.moveScreenState(to: .edit)
					}

				}
				.padding()
				.background(.background)
				.cornerRadius(12)
				.shadow(radius: 20)
				.frame(width: 500)
			}

		}
	}

	private var store: DesignFileStore {
		DesignFileStore(modelContext: modelContext)
	}
}

#Preview {
	HomeView()
		.environment(ViewModel())
}
