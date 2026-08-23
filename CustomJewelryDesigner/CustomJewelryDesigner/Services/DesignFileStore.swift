//
//  DesignFileStore.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 12/08/26.
//

import SwiftData
// DesignFileStore.swift
import SwiftUI

struct DesignFileStore {
	let modelContext: ModelContext

	//buat folder kosong
	@discardableResult
	func createDesignFolder(name: String) -> DesignFolder {
		let newFolder = DesignFolder(id: UUID(), name: name)
		modelContext.insert(newFolder)
		do {
			try modelContext.save()
			print("berhasil buat folder \(newFolder.name)")
		} catch {
			print("Failed to save folder: \(error)")
		}
		return newFolder
	}
	
	//edit nama folder
	func renameDesignFolder(design: DesignFolder, to newName: String) {
		design.name = newName
		do {
			try modelContext.save()
		} catch {
			print("Failed to update design folder name: \(error)")
		}
	}
	
	//tambah file ke folder
	func addFileToFolder(file: DesignFile, folder: DesignFolder) {
		file.folder = folder
		do {
			try modelContext.save()
		} catch {
			print("Failed to add file to folder: \(error)")
		}
	}
	
	//move to another folder
	func moveFileToAnotherFolder(file: DesignFile, folder: DesignFolder) {
		file.folder = folder
		do {
			try modelContext.save()
		} catch {
			print("Failed to move file to folder: \(error)")
		}
	}
	
	//keluarin file dari folder
	func removeFileFromFolder(file: DesignFile, folder: DesignFolder) {
		file.folder = nil
		do {
			try modelContext.save()
		} catch {
			print("Failed to remove file from folder: \(error)")
		}
	}
	
	//delete folder
	func deleteDesignFolder(_ file: DesignFolder) {
		modelContext.delete(file)
		do {
			try modelContext.save()
		} catch {
			print("Failed to delete folder: \(error)")
		}
	}

	//buat file
	func createDesignFile(name: String) -> DesignFile {
        
        let band = BandComponent(
            libraryAssetID: UUID(),
            assetStoragePath: "Flat_Band_Ring",
            name: "Flat Band Ring"
        )
        
        let design = Design(materialPreset: "Yellow Gold", band: band, gems: [])
        
		let newFile = DesignFile(
			id: UUID(),
			name: name,
			updatedAt: .now,
			ringPosition: .left,
			design: design
		)
		modelContext.insert(newFile)
		do {
			try modelContext.save()
			print("berhasil buat file design \(newFile.name)")
		} catch {
			print("Failed to save file: \(error)")
		}
        
        return newFile
	}

	//save design ke file
	func addDesign(
		to file: DesignFile,
		name: String,
		materialPreset: String,
		bandComponent: BandComponent
	) {
		let design = Design(
			materialPreset: materialPreset,
			band: bandComponent,
			gems: []
		)
		file.design = design
		do {
			try modelContext.save()
		} catch {
			print("Failed to save design file: \(error)")
		}
	}

	//duplicate design file
	func duplicateDesignFile(_ file: DesignFile) {
		let newFile = createDesignFile(name: file.name)
		addDesign(to: newFile, name: file.name, materialPreset: file.design?.materialPreset ?? "Yellow Gold", bandComponent: (file.design?.band ?? .none)!)
		
		modelContext.insert(newFile)
		do {
			try modelContext.save()
			print("berhasil duplicate file design \(newFile.name)")
		} catch {
			print("Failed to duplicate file: \(error)")
		}
	}

	//save updated design
	func saveUpdatedDesign(
		to file: DesignFile,
		to position: DesignFile.RingPosition,
		design: Design
	) {
		file.updatedAt = .now
		file.ringPosition = position
		file.design = design
		do {
			try modelContext.save()
		} catch {
			print("Failed to update design file: \(error)")
		}
	}
	
	//rename design file
	func renameDesignFile(design: DesignFile, to newName: String) {
		design.name = newName
		design.updatedAt = .now
		do {
			try modelContext.save()
		} catch {
			print("Failed to update design file name: \(error)")
		}
	}
	
	//delete design file
	func deleteDesignFile(_ file: DesignFile) {
		modelContext.delete(file)
		do {
			try modelContext.save()
		} catch {
			print("Failed to delete design file: \(error)")
		}
	}

//	func swapGem(in design: Design, oldGem: GemComponent, newGem: GemComponent) {
//		if let index = design.gems.firstIndex(where: { $0.id == oldGem.id }) {
//			design.gems.remove(at: index)
//			modelContext.delete(oldGem)       // remove old row from DB
//			design.gems.append(newGem)        // add new one
//		}
//		design.updatedAt = .now
//		try? modelContext.save()
//	}
}
