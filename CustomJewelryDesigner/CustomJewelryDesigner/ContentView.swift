//
//  ContentView.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import SwiftUI
import Supabase
import SwiftData

struct ContentView: View {
    @State private var onboarding = OnBoardingService()
    @State private var vm = ViewModel()
    
    var body: some View {
        Group {
            if !onboarding.hasCompletedTutorial {
                TutorialFlowView(onboarding: onboarding)
            } else {
                vm.sceneState.viewAssociated(using: vm)
            }
        }
        .environment(onboarding)
        .environment(vm)
    }
}

#Preview {
    ContentView()
        .environment(ViewModel())
}
