//
//  FolderView.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 15/08/26.
//
import SwiftUI
import SwiftData

struct FolderView: View {
	@Environment(ViewModel.self) private var vm
	@Environment(\.modelContext) private var modelContext
	
	@Query(sort: \DesignFile.updatedAt, order: .reverse) var designFiles: [DesignFile]
	@Query(sort: \DesignFolder.name, order: .reverse) var designFolder: [DesignFolder]
	
	var folder: DesignFolder
	// only files inside one folder
	var fileInTheFolder: [DesignFile] {
		designFiles.filter { $0.folder == folder }
	}
	
	
	@State private var isSelecting: Bool = false
	@State private var selectedItemIDs: Set<UUID> = []
	
	let columns = [
		GridItem(
			.flexible(),
			spacing: 50,
			alignment: .top
		),
		GridItem(
			.flexible(),
			spacing: 50,
			alignment: .top
		),
		GridItem(
			.flexible(),
			spacing: 50,
			alignment: .top
		),
		GridItem(
			.flexible(),
			spacing: 50,
			alignment: .top
		),
		GridItem(
			.flexible(),
			spacing: 50,
			alignment: .top
		),
	]
	
	var body: some View {
		VStack {
			HStack {
				Button {
					vm.moveScreenState(to: .home)
				} label: {
					Image(systemName: "chevron.left")
				}
				.clipShape(.circle)
				.buttonStyle(.bordered)

				Text(folder.name)
				
				Button(isSelecting ? "Cancel" : "Select") {
					isSelecting.toggle()
					if !isSelecting {
						selectedItemIDs.removeAll()
					}
				}
			}
			
			ScrollView(.vertical, showsIndicators: true) {
				LazyVGrid(columns: columns, spacing: 50) {
					ForEach(fileInTheFolder) { file in
						HomeCard(
							preview: Image(.detail34),
							title: file.name,
							updatedAt: file.updatedAt,
							isSelecting: isSelecting,
							isSelected: selectedItemIDs.contains(file.id)
						)
						.onTapGesture {
							handleTap(on: file)
						}
					}

				}
			}
			
			Text(
				selectedItemIDs.isEmpty
					? "is empty"
					: designFiles
						.filter { selectedItemIDs.contains($0.id) }
						.map { $0.name }
						.joined(separator: ", ")
			)
			if isSelecting && !selectedItemIDs.isEmpty {
				HStack {
					Button("Delete", role: .destructive) {
						deleteSelected()
					}
				}
			}
			
		}
	}
	
	private func handleTap(on file: DesignFile) {
		if isSelecting {
			if selectedItemIDs.contains(file.id) {
				selectedItemIDs.remove(file.id)
			} else {
				selectedItemIDs.insert(file.id)
			}
		} else {
			vm.moveScreenState(to: .edit(file))
		}
	}
	
	private func deleteSelected() {
		let filesToDelete = designFiles.filter {
			selectedItemIDs.contains($0.id)
		}
		for file in filesToDelete {
			store.deleteDesignFile(file)
		}
		selectedItemIDs.removeAll()
		isSelecting = false
	}
	
	private var store: DesignFileStore {
		DesignFileStore(modelContext: modelContext)
	}

}

#Preview {
	FolderView(folder: DesignFolder(id: UUID(), name: "folder test"))
		.environment(ViewModel())
}
