//
//  DesignFileStore.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 12/08/26.
//

// DesignFileStore.swift
import SwiftUI
import SwiftData

struct DesignFileStore {
	let modelContext: ModelContext

	func createDesignFile(name: String) {
		let newFile = DesignFile(id: UUID(), name: name, createdAt: .now, updatedAt: .now, designs: [])
		modelContext.insert(newFile)
		try? modelContext.save()
		print("berhasil save \(newFile.name)")
	}

	func addDesign(to file: DesignFile, name: String, materialPreset: String, bandComponent: BandComponent) {
		let design = Design(id: UUID(), name: name, materialPreset: materialPreset, createdAt: .now, updatedAt: .now, band: bandComponent, gems: [])
		file.designs.append(design)
		try? modelContext.save()
	}

	// fetch, update, delete functions go here too
}
