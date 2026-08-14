//
//  CustomJewelryDesignerApp.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import SwiftUI
import SwiftData

@main
struct CustomJewelryDesignerApp: App {
	@State private var vm = ViewModel()
	
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DesignFile.self,
			Design.self,
			BandComponent.self,
			GemComponent.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
				.environment(vm)
        }
        .modelContainer(sharedModelContainer)
    }
}
