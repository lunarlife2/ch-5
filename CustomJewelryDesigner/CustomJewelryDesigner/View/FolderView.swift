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
	
	enum ContentLayout {
		case grid
		case list
	}
	
	@State private var layout: ContentLayout = .grid
	@State private var isShowing: Bool = false
	@State private var fileName: String = ""
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
		ZStack {
			VStack {
				HStack {
					if !isSelecting {
						Button {
							vm.moveScreenState(to: .home)
						} label: {
							Image(systemName: "chevron.left")
						}
						.clipShape(.circle)	.buttonStyle(.bordered)
						.foregroundStyle(Color.black)

						Spacer()

						Text(folder.name)
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
							}
							//.foregroundStyle(Color.black)
							.buttonStyle(.bordered)
							.disabled(true)
							
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
						.tint(Color.main)

					}
				}
				.padding(.vertical)
				
				switch layout {
				case .grid:
					ScrollView(.vertical, showsIndicators: true) {
						LazyVGrid(columns: columns, spacing: 50) {
							ForEach(fileInTheFolder) { file in
								HomeCard(
									preview: Image(thumbnailData: file.thumbnailData),
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
						
						List(fileInTheFolder) { file in
							FileListRow(
								preview: Image(thumbnailData: file.thumbnailData),
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
				.tint(Color.main)
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
					}

				VStack(alignment: .leading) {
					HStack {
						Text("File Name")
							.font(.system(size: 20, weight: .semibold))
						Spacer()
						Button {
							isShowing = false
							fileName = ""
						} label: {
							Image(systemName: "xmark")
						}
					}

					TextField(
						"File name" ,
						text: $fileName
					)
					.textFieldStyle(.roundedBorder)

					Button {
						if fileName.isEmpty {
							return
						}

							let file = store.createDesignFile(name: fileName)
						store.addFileToFolder(file: file, folder: folder)
							vm.moveScreenState(to: .edit(file))

						isShowing = false
						fileName = ""
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

	
	private var store: DesignFileStore {
		DesignFileStore(modelContext: modelContext)
	}

}

#Preview {
    FolderView(folder: DesignFolder(id: UUID(), name: "folder test"))
        .environment(ViewModel())
}
