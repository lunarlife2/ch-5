//
//  TutorialView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 24/08/26.
//

import SwiftUI

struct TutorialView: View {
    var onboarding: OnBoardingService
    var tutorialViewModel: TutorialViewModel
    var onCreateFile: (String) -> Void
    var showsCreateCoachMark: Bool
    
    @State private var isReady = false
    @State private var showCreateSheet = false
    
    var body: some View {
        ZStack {
            homeBackground
            
            if isReady && showsCreateCoachMark && !showCreateSheet {
                SpotlightOverlay(targetFrame: tutorialViewModel.frame(for: .createButton)) {
                    CoachMarkCard(
                        title: "Start Here",
                        subtitle: "Create your first ring",
                        stepInfo: (1, 8),
                        onSkip: {
                            onboarding.hasCompletedTutorial = true
                        },
                        onNext: nil,
                        width: 260,
                        height: nil
                    )
                }
            }
            
            if showCreateSheet {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                CreateFileSheet(
                    onCancel: { showCreateSheet = false },
                    onCreate: { name in
                        showCreateSheet = false
                        onCreateFile(name)
                    }
                )
            }
        }
        .task {
            if !onboarding.hasRequestedPermissions {
                await onboarding.requestCameraAndPhotoAccess()
            }
            isReady = true
        }
    }
    
    private var homeBackground: some View {
        ZStack {
            VStack {
                HStack(spacing: 20) {
                    Button("My Sizes", systemImage: "hand.raised") {}
                        .buttonStyle(.bordered)
                        .foregroundStyle(Color.black)
                    Text("Projects")
                        .font(.system(size: 20, weight: .semibold))
                    Spacer()
                    Button("Select", systemImage: "checkmark.circle") {}
                        .foregroundStyle(Color.black).buttonStyle(.bordered).disabled(true)
                    Button("View", systemImage: "square.split.2x2") {}
                        .foregroundStyle(Color.black).buttonStyle(.bordered).disabled(true)
                    Button("Filters", systemImage: "line.3.horizontal.decrease") {}
                        .foregroundStyle(Color.black).buttonStyle(.bordered).disabled(true)
                }
                Spacer()
            }
            .padding(.horizontal, 100)
            .padding(.vertical)
            
            Button("Create", systemImage: "plus") { showCreateSheet = true }
                .buttonStyle(.glassProminent)
                .tint(Color.appPrimary)
                .controlSize(.large)
                .tutorialAnchor(.createButton, viewModel: tutorialViewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
        }
    }
}
