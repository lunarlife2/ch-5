//
//  MeasureView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 20/08/26.
//

import SwiftData
import SwiftUI

struct MeasureView: View {
	@Bindable var bandGemViewModel: BandGemViewModel
	@State private var ringSizeViewModel: RingSizerViewModel?

	let hand: Hand
	var initialMeasurement: FingerMeasurement? = nil

	var onBack: () -> Void = {}
	var onApply: (RingSizeOption) -> Void = { _ in }

	@State private var viewModel: RingSizerViewModel?

	let handFinger: HandFinger  // NEW

	@Environment(\.modelContext) private var modelContext  // NEW
	@Environment(\.dismiss) private var dismiss  // NEW
	@Query private var savedSizes: [SavedRingSize]  // NEW

	private var existing: SavedRingSize? {  // NEW
		savedSizes.first { $0.handFinger == handFinger }
	}

	//    let onBack: () -> Void

	var body: some View {
		Group {
			if let ringSizeViewModel {
				content(ringSizeViewModel)
			} else {
				ProgressView("Preparing measurement...")
			}
		}
		.background {
			ScreenReader { screen in
				print("📱 ScreenReader fired, screen: \(screen)")
				if ringSizeViewModel == nil,
					let pointsPerMM = DeviceCalibration.pointsPerMM(for: screen)
					
				{
					print("📏 pointsPerMM result: \(String(describing: pointsPerMM))")
					let startSystem =
						initialMeasurement?.ringSizeSystem
						?? bandGemViewModel.selectedRingSizeSystem

					let newViewModel = RingSizerViewModel(
						pointsPerMM: pointsPerMM,
						ringSizeSystem: startSystem
					)

					bandGemViewModel.selectedRingSizeSystem = startSystem

					if let initialMeasurement,
						let option = initialMeasurement.ringSizeOption
					{
						newViewModel.setSeparation(
							CGFloat(option.diameterMM) * pointsPerMM
						)
					} else if let existing = bandGemViewModel.selectedRingSize {
						newViewModel.setSeparation(
							CGFloat(existing.diameterMM) * pointsPerMM
						)
					} else {
						newViewModel.reset()
					}

					ringSizeViewModel = newViewModel
				}
			}
		}
	}

	//    @ViewBuilder
	//    private func caliperContent(
	//        _ viewModel: RingSizerViewModel
	//	) -> some View {
	//
	//		VStack(spacing: 24) {
	//
	//			GlassButton {
	//				saveAndDismiss(viewModel)
	//			} label: {
	//				Image(systemName: "chevron.left")
	//			}
	//		}
	@ViewBuilder
	private func content(_ viewModel: RingSizerViewModel) -> some View {
		VStack(spacing: 20) {
			ZStack {
				Text("Measure My Ring Size")
					.font(.title3.bold())

				HStack {
					GlassButton {
						onBack()
					} label: {
						Image(systemName: "chevron.left")
					}
					Spacer()
				}
			}

			Menu {
				ForEach(RingSizeSystem.allCases) { system in
					Button {
						bandGemViewModel.selectedRingSizeSystem = system
					} label: {
						HStack {
							Text(system.title)

							if system == bandGemViewModel.selectedRingSizeSystem
							{
								Image(systemName: "checkmark")
							}
						}
					}
				}
			} label: {
				HStack {
					Text(bandGemViewModel.selectedRingSizeSystem.title)
						.foregroundStyle(.black)

					Image(systemName: "chevron.up.chevron.down")
				}
			}
			.padding(.horizontal, 14)
			.padding(.vertical, 10)

			HStack(spacing: 20) {
				Button {
					stepRingSize(by: -1, viewModel: viewModel)
				} label: {
					Image(systemName: "minus")
						.frame(minWidth: 34, minHeight: 34)
				}

				.buttonStyle(.glass)
				.disabled(!canStep(by: -1, viewModel: viewModel))

				Text(currentSizeLabel(viewModel))
					.font(.system(size: 34, weight: .black, design: .rounded))
					.monospacedDigit()
					.frame(minWidth: 70)

				Button {
					stepRingSize(by: 1, viewModel: viewModel)
				} label: {
					Image(systemName: "plus")
						.frame(minWidth: 34, minHeight: 34)
				}

				.buttonStyle(.glass)
				.disabled(!canStep(by: 1, viewModel: viewModel))
			}

			HStack(spacing: 24) {
				metricBadge(
					label: "Diameter",
					value: String(format: "%.1f mm", viewModel.diameterMM)
				)
				metricBadge(
					label: "Circumference",
					value: String(
						format: "%.1f mm",
						viewModel.closestRingSize?.circumferenceMM
							?? viewModel.diameterMM * .pi
					)
				)
			}

			CaliperTrack(
				hand: hand,
				separationPoints: viewModel.separationPoints,
				minSeparation: viewModel.minSeparation,
				maxSeparation: viewModel.maxSeparation,
				onDrag: { newSeparation in
					viewModel.setSeparation(newSeparation)
				}
			)
			.frame(width: 350, height: 313)
			.padding(hand == .right ? .trailing : .leading, 300)

			Spacer(minLength: 0)

			HStack {
				if initialMeasurement != nil {
					Button {
						snapToNearestSize(viewModel)
					} label: {
						Text("Update Size")
							.font(.system(size: 19, weight: .semibold))
							.padding(10)
					}
					.buttonStyle(.glass)

				}

				Spacer()

				Button {
					if let closest = viewModel.closestRingSize {
						onApply(closest)
					}
					onBack()
				} label: {
					Text("Apply")
						.font(.system(size: 19, weight: .semibold))
						.padding(10)
				}
				.buttonStyle(.glassProminent)
			}
			.padding(.horizontal, 20)
		}
		.padding()
	}

	private func currentIndex(_ viewModel: RingSizerViewModel) -> Int? {
		guard let closest = viewModel.closestRingSize else { return nil }
		return viewModel.availableOptions.firstIndex { $0.id == closest.id }
	}

	private func canStep(by delta: Int, viewModel: RingSizerViewModel) -> Bool {
		guard let index = currentIndex(viewModel) else { return false }
		let target = index + delta
		return viewModel.availableOptions.indices.contains(target)
	}

	private func stepRingSize(by delta: Int, viewModel: RingSizerViewModel) {
		guard let index = currentIndex(viewModel) else { return }
		let target = index + delta
		guard viewModel.availableOptions.indices.contains(target) else {
			return
		}

		let option = viewModel.availableOptions[target]
		viewModel.setSeparation(
			CGFloat(option.diameterMM) * viewModel.pointsPerMM
		)
	}

	private func snapToNearestSize(_ viewModel: RingSizerViewModel) {
		guard let closest = viewModel.closestRingSize else { return }
		viewModel.setSeparation(
			CGFloat(closest.diameterMM) * viewModel.pointsPerMM
		)
	}

	private func currentSizeLabel(_ viewModel: RingSizerViewModel) -> String {
		viewModel.closestRingSize?.size(
			for: bandGemViewModel.selectedRingSizeSystem
		) ?? "–"
	}

	@ViewBuilder
	private func metricBadge(label: String, value: String) -> some View {
		HStack(spacing: 6) {
			Text(label)
				.foregroundStyle(.secondary)
			Text(value)
				.fontWeight(.semibold)
				.padding(.horizontal, 10)
				.padding(.vertical, 4)
				.background(Capsule().fill(Color(uiColor: .systemGray6)))
		}
		.font(.subheadline)
	}

	private struct ScreenReader: UIViewRepresentable {
		let onScreen: (UIScreen) -> Void

		func makeUIView(context: Context) -> UIView {
			let view = UIView()
			view.backgroundColor = .clear
			return view
		}

		func updateUIView(_ uiView: UIView, context: Context) {
			DispatchQueue.main.async {
				guard let screen = uiView.window?.windowScene?.screen else {
					return
				}
				onScreen(screen)
			}
		}
	}

//	private func saveAndDismiss(_ viewModel: RingSizerViewModel) {
//		if let ring = viewModel.closestRingSize {
//			if let existing {
//				existing.sizeID = ring.id
//				existing.system = bandGemViewModel.selectedRingSizeSystem
//				existing.updatedAt = Date()
//			} else {
//				modelContext.insert(
//					SavedRingSize(
//						handFinger: handFinger,
//						system: bandGemViewModel.selectedRingSizeSystem,
//						sizeID: ring.id
//					)
//				)
//			}
//		}
//		dismiss()
//	}

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
	MeasureView(
		bandGemViewModel: BandGemViewModel(), hand: .left,
		handFinger: .leftmiddle
	)
}
