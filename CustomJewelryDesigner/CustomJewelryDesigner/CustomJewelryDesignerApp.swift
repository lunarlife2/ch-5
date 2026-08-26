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
//	@State private var vm = ViewModel()
	
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DesignFile.self,
			Design.self,
			BandComponent.self,
			GemComponent.self,
            SnapPointRecord.self,
            FingerMeasurement.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, allowsSave: true)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
//			vm.sceneState.viewAssociated()
//				.environment(vm)
            ContentView()
				.environment(\.font, .appFont(size: 17, weight: .regular))
        }
        .modelContainer(sharedModelContainer)
    }
}
