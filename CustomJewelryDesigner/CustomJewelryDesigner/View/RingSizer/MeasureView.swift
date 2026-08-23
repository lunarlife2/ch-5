//
//  MeasureView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 20/08/26.
//

import SwiftUI
import SwiftData

struct MeasureView: View {
    @Bindable var bandGemViewModel: BandGemViewModel
    @State private var viewModel: RingSizerViewModel?
	
	let handFinger: HandFinger                     // NEW

		@Environment(\.modelContext) private var modelContext   // NEW
		@Environment(\.dismiss) private var dismiss              // NEW
		@Query private var savedSizes: [SavedRingSize]           // NEW

		private var existing: SavedRingSize? {                   // NEW
			savedSizes.first { $0.handFinger == handFinger }
		}
    
//    let onBack: () -> Void
    
    var body: some View {
        Group {
            if let viewModel {
                caliperContent(viewModel)
            } else {
                ProgressView("Preparing measurement...")
            }
        }
        .background {
            ScreenReader { screen in
                if viewModel == nil,
                   let pointsPerMM = DeviceCalibration.pointsPerMM(
                    for: screen
                   ) {
                    viewModel = RingSizerViewModel(
                        pointsPerMM: pointsPerMM
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func caliperContent(
        _ viewModel: RingSizerViewModel
    ) -> some View {
        
        VStack(spacing: 24) {
            
            GlassButton {
				saveAndDismiss(viewModel)
            } label: {
                Image(systemName: "chevron.left")
            }

            
            Text("Ukur Diameter Jari")
                .font(.title2.bold())
            
            Text("Tempelkan jari pada layar")
                .foregroundStyle(.secondary)
            
            ZStack {
                
                FingerGuide()
                    .frame(
                        width: 100,
                        height: 260
                    )
                
                CaliperJaws(
                    separation: Binding(
                        get: {
                            viewModel.separationPoints
                        },
                        set: {
                            viewModel.setSeparation($0)
                        }
                    ),
                    trackWidth: 280,
                    minSeparation: viewModel.minSeparation,
                    maxSeparation: viewModel.maxSeparation
                )
            }
            .frame(height: 280)
            
            VStack(spacing: 6) {
                
                Text(
                    String(
                        format: "%.1f mm",
                        viewModel.diameterMM
                    )
                )
                .font(
                    .system(
                        .title,
                        design: .rounded
                    )
                    .monospacedDigit()
                )
                
                if let ring = viewModel.closestRingSize,
                   let size = ring.size(
                    for: bandGemViewModel.selectedRingSizeSystem
                   ) {
                    
                    Text(
                        "\(bandGemViewModel.selectedRingSizeSystem.title) \(size)"
                    )
                    .font(.headline)
                }
            }
            
            Button("Reset") {
                viewModel.reset()
            }
        }
        .padding()
    }
    
    private struct ScreenReader: UIViewRepresentable {
        let onScreen: (UIScreen) -> Void

        func makeUIView(
            context: Context
        ) -> UIView {
            let view = UIView()
            view.backgroundColor = .clear
            return view
        }

        func updateUIView(
            _ uiView: UIView,
            context: Context
        ) {
            DispatchQueue.main.async {
                guard let screen = uiView.window?.windowScene?.screen else {
                    return
                }

                onScreen(screen)
            }
        }
    }
	
	private func saveAndDismiss(_ viewModel: RingSizerViewModel) {
		if let ring = viewModel.closestRingSize {
			if let existing {
				existing.sizeID = ring.id
				existing.system = bandGemViewModel.selectedRingSizeSystem
				existing.updatedAt = Date()
			} else {
				modelContext.insert(SavedRingSize(
					handFinger: handFinger,
					system: bandGemViewModel.selectedRingSizeSystem,
					sizeID: ring.id
				))
			}
		}
		dismiss()
	}
	
    struct FingerGuide: View {

        var body: some View {

            RoundedRectangle(cornerRadius: 50)
                .stroke(
                    .secondary.opacity(0.4),
                    style: StrokeStyle(
                        lineWidth: 2,
                        dash: [8, 6]
                    )
                )
                .overlay {
                    Text("Letakkan jari di sini")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
        }
    }
}
#Preview {
	MeasureView(bandGemViewModel: BandGemViewModel(), handFinger: .leftpinky)
}
