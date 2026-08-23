//
//  ContentView.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

//import SwiftUI
//import SwiftData
//
//struct ContentView: View {
//    @Environment(\.modelContext) private var modelContext
//    @Query private var items: [Item]
//
//    var body: some View {
//        NavigationSplitView {
//            List {
//                ForEach(items) { item in
//                    NavigationLink {
//                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
//                    } label: {
//                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
//                    }
//                }
//                .onDelete(perform: deleteItems)
//            }
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    EditButton()
//                }
//                ToolbarItem {
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }
//            }
//        } detail: {
//            Text("Select an item")
//        }
//    }
//
//    private func addItem() {
//        withAnimation {
//            let newItem = Item(timestamp: Date())
//            modelContext.insert(newItem)
//        }
//    }
//
//    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
//            for index in offsets {
//                modelContext.delete(items[index])
//            }
//        }
//    }
//}

import SwiftUI
import Supabase
import SwiftData

struct ContentView: View {

    @Environment(ViewModel.self) private var vm

    var body: some View {
//        switch vm.sceneState {
//
//        case .home:
//            HomeView()
//
//        case .edit(let file):
//            EditView(designFile: file)
//            
//        case .detail(let file):
//            DetailView(designFile: file)
//            
//        default:
//            HomeView()
//        }
    }
}

#Preview {
    ContentView()
        .environment(ViewModel())
}

//#Preview {
//    ContentView()
//        .modelContainer(for: Item.self, inMemory: true)
//}
