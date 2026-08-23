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

	@Query(sort: \DesignFile.updatedAt, order: .reverse) var designFiles:
		[DesignFile]
	@Query(sort: \DesignFolder.name) var designFolders: [DesignFolder]

	// only files not inside any folder
	var standaloneFiles: [DesignFile] {
		designFiles.filter { $0.folder == nil }
	}

	enum ContentLayout {
		case grid
		case list
	}
	@State private var layout: ContentLayout = .grid

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
					if !isSelecting {
						Button("My Sizes", systemImage: "hand.raised") {
							vm.moveScreenState(to: .handSize)
						}
						.buttonStyle(.bordered)
						.foregroundStyle(Color.black)

						Spacer()

						Text("Projects")
							.font(.system(size: 20, weight: .semibold))

						Spacer()

						Group {
							Button("Select", systemImage: "checkmark.circle") {
								isSelecting.toggle()
								if !isSelecting {
									selectedItemIDs.removeAll()
								}
							}
							.foregroundStyle(Color.black)
							.buttonStyle(.bordered)

							Menu {
								Button {
									layout = .grid
								} label: {
									Label(
										"Grid",
										systemImage: layout == .grid
											? "checkmark" : ""
									)
								}
								Button {
									layout = .list
								} label: {
									Label(
										"List",
										systemImage: layout == .list
											? "checkmark" : ""
									)
								}
							} label: {
								Label("View", systemImage: "square.split.2x2")
							}
							.buttonStyle(.bordered)
							.foregroundStyle(Color.black)

							Button(
								"Filters",
								systemImage: "line.3.horizontal.decrease"
							) {
								//filter
							}
							.buttonStyle(.bordered)
							.foregroundStyle(Color.black)
							//.disabled(true)
						}
					} else {
						Text("\(selectedItemIDs.count) Projects selected")
							.font(.system(size: 20, weight: .semibold))

						Spacer()

						Group {
							Button("Group", systemImage: "square.2.layers.3d") {
								isShowing.toggle()
								fileOrFolder.toggle()
							}
							.foregroundStyle(Color.black)
							.buttonStyle(.bordered)
							
							Button(
								"Duplicate",
								systemImage: "document.on.document"
							) {
								duplicateSelected()
							}
							.buttonStyle(.bordered)
							.foregroundStyle(Color.black)

							Button("Delete", systemImage: "trash") {
								deleteSelected()
							}
							.buttonStyle(.bordered)
							.foregroundStyle(Color.black)
						}

						Button {
							isSelecting.toggle()
							selectedItemIDs.removeAll()
						} label: {
							Image(systemName: "xmark")
						}
						.clipShape(.circle)
						.buttonStyle(.borderedProminent)

					}
				}
				.padding(.vertical)

				switch layout {
				case .grid:
					ScrollView(.vertical, showsIndicators: true) {
						LazyVGrid(columns: columns, spacing: 50) {
							ForEach(designFolders) { folder in
								FolderCard(
									preview: Image(.detailBottom),
									title: folder.name
								)  //previewImage(for: folder)
								.onTapGesture {
									vm.moveScreenState(to: .folder(folder))  // navigate in, unrelated to selection
								}
							}

							ForEach(standaloneFiles) { file in
								HomeCard(
									preview: Image(.detail34),
									title: file.name,
									updatedAt: file.updatedAt,
									isSelecting: isSelecting,
									isSelected: selectedItemIDs.contains(
										file.id
									)
								)
								.onTapGesture {
									handleTap(on: file)
								}
							}

						}
					}

				case .list:
					VStack(spacing: 0) {
						FileListHeader()
						
						Divider()
						
						List(standaloneFiles) { file in
							FileListRow(
								preview: Image(.detail34),
								title: file.name,
								updatedAt: file.updatedAt,
								isSelecting: isSelecting,
								isSelected: selectedItemIDs.contains(file.id)
							)
							.listRowInsets(EdgeInsets())  // let FileListRow own its own padding
							.listRowBackground(Color.clear)  // ...and default row background
							.onTapGesture {
								handleTap(on: file)
							}
						}
						.listStyle(.plain)
						.scrollContentBackground(.hidden)  // this is the actual fix for the grey — List's system background shows through otherwise
						.background(Color.white)
					}
					
				}
			}
			.padding(.horizontal, 100)

			if !isSelecting {
				Button("Create", systemImage: "plus") {
					isShowing.toggle()
				}
				.buttonStyle(.glassProminent)
				.tint(Color.black)
				.controlSize(.large)
				.frame(
					maxWidth: .infinity,
					maxHeight: .infinity,
					alignment: .bottomTrailing
				)
				.padding(.horizontal, 40)
				.padding(.vertical, 20)
			}

			if isShowing {
				Color.black.opacity(0.4)
					.ignoresSafeArea()
					.onTapGesture {
						isShowing = false
						fileName = ""
						folderName = ""
					}

				VStack(alignment: .leading) {
					HStack {
						Text(fileOrFolder ? "File Name" : "Folder Name")
							.font(.system(size: 20, weight: .semibold))
						Spacer()
						Button {
							isShowing = false
							fileName = ""
							folderName = ""
						} label: {
							Image(systemName: "xmark")
						}
					}

					TextField(
						fileOrFolder ? "File name" : "Folder Name",
						text: fileOrFolder ? $fileName : $folderName
					)
					.textFieldStyle(.roundedBorder)

					Button {
						if fileName.isEmpty && folderName.isEmpty {
							return
						}

						if fileOrFolder {
							let file = store.createDesignFile(name: fileName)
							vm.moveScreenState(to: .edit(file))
						} else {
							let newFolder = store.createDesignFolder(
								name: folderName
							)
							groupSelected(folder: newFolder)
						}

						isShowing = false
						fileName = ""
						folderName = ""
					} label: {
						Text("Create")
							.frame(maxWidth: .infinity)
					}
					.buttonStyle(.borderedProminent)

				}
				.padding()
				.background(.background)
				.cornerRadius(12)
				.shadow(radius: 20)
				.frame(width: 400)
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

	private func duplicateSelected() {
		let filesToDuplicate = designFiles.filter {
			selectedItemIDs.contains($0.id)
		}
		for file in filesToDuplicate {
			store.duplicateDesignFile(file)
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

struct FileListHeader: View {
	enum ListColumns {
		static let thumbnail: CGFloat = 60
		static let name: CGFloat = 200
		// "Last Updated" and "Share" split the remaining space
	}

	var body: some View {
		HStack(spacing: 16) {
			Text("Name")
				.frame(width: ListColumns.name, alignment: .leading)

			Text("Last Updated")
				.frame(maxWidth: .infinity, alignment: .center)

			Text("Share")
				.frame(width: 60, alignment: .trailing)
		}
		.font(.system(size: 13))
		.foregroundStyle(.secondary)
		.padding(.horizontal, 20)
		.padding(.vertical, 20)
	}
}

#Preview {
	HomeView()
		.environment(ViewModel())
}
