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

	@Query(sort: \DesignFile.updatedAt, order: .reverse) var designFiles: [DesignFile]
	@Query(sort: \DesignFolder.name) var designFolders: [DesignFolder]

	// only files not inside any folder
	var standaloneFiles: [DesignFile] {
		designFiles.filter { $0.folder == nil }
	}

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

	@State private var isShowing: Bool = false
	@State private var fileName: String = ""
	@State private var folderName: String = ""
	@State private var selectedItemIDs: Set<UUID> = []
	@State private var isSelecting: Bool = false
	@State private var fileOrFolder: Bool = true

	var body: some View {
		ZStack {
			VStack {
				HStack {
					Text("Projects")
					Button(isSelecting ? "Cancel" : "Select") {
						isSelecting.toggle()
						if !isSelecting {
							selectedItemIDs.removeAll()
						}
					}
				}

				ScrollView(.vertical, showsIndicators: true) {
					LazyVGrid(columns: columns, spacing: 50) {
						ForEach(designFolders) { folder in
									FolderCard(
										preview: Image(.detailBottom),
										title: folder.name
									) //previewImage(for: folder)
									.onTapGesture {
										vm.moveScreenState(to: .folder(folder)) // navigate in, unrelated to selection
									}
								}
						
						ForEach(standaloneFiles) { file in
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
						Button("Group") {
							// group action
							isShowing.toggle()
							fileOrFolder.toggle()
						}
					}
				}

				Button("New") {
					isShowing.toggle()
				}
			}
			.padding(.horizontal, 100)

			if isShowing {
				Color.black.opacity(0.4)
					.ignoresSafeArea()
					.onTapGesture {
						isShowing = false
						fileName = ""
						folderName = ""
					}

				VStack {
					Text(fileOrFolder ? "File Name" : "Folder Name")
						.font(.headline)
					TextField(fileOrFolder ? "File name" : "Folder Name", text: fileOrFolder ? $fileName : $folderName)
						.textFieldStyle(.roundedBorder)

					Button("Close") {
						isShowing = false
						fileName = ""
						folderName = ""
					}
					Button("Create") {
						if fileName.isEmpty && folderName.isEmpty {
							return
						}
						
						if fileOrFolder {
							store.createDesignFile(name: fileName)
							vm.moveScreenState(to: .edit)
						} else {
							let newFolder = store.createDesignFolder(name: folderName)
							groupSelected(folder: newFolder)
						}

						isShowing = false
						fileName = ""
						folderName = ""
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

	private func handleTap(on file: DesignFile) {
		if isSelecting {
			if selectedItemIDs.contains(file.id) {
				selectedItemIDs.remove(file.id)
			} else {
				selectedItemIDs.insert(file.id)
			}
		} else {
			vm.moveScreenState(to: .edit)
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
	
	private func groupSelected(folder: DesignFolder) {
		let filesToGroup = designFiles.filter {
			selectedItemIDs.contains($0.id)
		}
		for file in filesToGroup {
			store.addFileToFolder(file: file, folder: folder)
		}
		selectedItemIDs.removeAll()
		isSelecting = false
	}

	private var store: DesignFileStore {
		DesignFileStore(modelContext: modelContext)
	}
}

#Preview {
	HomeView()
		.environment(ViewModel())
}
