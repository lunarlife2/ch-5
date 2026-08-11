//
//  HomeView.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
	@Environment(\.modelContext) private var modelContext
	@Query(sort: \DesignFile.updatedAt, order: .reverse)
		private var designFiles: [DesignFile]
	
	var body: some View {
		Text("HomeView")
		List(designFiles) { file in
					Text(file.name)
				}
		Button("Create") {
					let store = DesignFileStore(modelContext: modelContext)
					store.createDesignFile(name: "My Collection")
				}

	}
}

#Preview {
	HomeView()
}
