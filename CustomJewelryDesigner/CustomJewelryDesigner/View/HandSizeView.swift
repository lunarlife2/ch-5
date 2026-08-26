//
//  HandSizeView.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 21/08/26.
//

import SwiftData
import SwiftUI

struct HandSizeView: View {
	@Environment(ViewModel.self) private var vm
	@Environment(\.modelContext) private var modelContext
	@State private var bandGemViewModel = BandGemViewModel()  // owned here, passed down

	private var store: HandProfileStore { HandProfileStore(modelContext: modelContext) }
	
	
	@Environment(\.dismiss) private var dismiss
	@State private var measurements: [FingerMeasurement] = []

	var body: some View {
		NavigationStack {
			ZStack {
				VStack {
					Text("Hand Profile")
						.font(.appFont(size: 28, weight: .bold))
					Text(
						"Save your measurements and tone for quick virtual try-ons."
					)
					.font(.appFont(size: 17, weight: .regular))
					.foregroundStyle(Color.gray)

					Spacer()

					Text("Tap a finger to add or edit a size")
						.font(.appFont(size: 17, weight: .regular))
						.foregroundStyle(Color.gray)

					Spacer()

					HStack(spacing: 10) {
						Text("System")
						Picker(
							"",
							selection: $bandGemViewModel.selectedRingSizeSystem
						) {
							ForEach(RingSizeSystem.allCases) { system in
								Text(system.title)
									.tag(system)
							}
						}
						.tint(.secondary)
						.labelsHidden()
					}
					.padding(.horizontal, 50)
				}
				.padding(.horizontal, 100)
				.padding(.top, 20)

				VStack {
					HStack(spacing: 180) {
						HandView(hand: .left, measurement: measurements, selectedRingSize: bandGemViewModel.selectedRingSizeSystem)
						HandView(hand: .right, measurement: measurements,selectedRingSize: bandGemViewModel.selectedRingSizeSystem)
					}
					.frame(maxHeight: .infinity, alignment: .bottom)
				}
				.navigationDestination(for: HandFinger.self) { handFinger in
					MeasureView(
						bandGemViewModel: bandGemViewModel,
						handFinger: handFinger, hand: handFinger.hand,
						initialMeasurement: store.measurement(for: handFinger),
						onApply: { ringSize in
							applyMeasurement(ringSize, handFinger: handFinger)
						}
					)
				}

				Button {
					vm.moveScreenState(to: .home)
				} label: {
					Image(systemName: "chevron.left")
						.foregroundStyle(Color.black)
						.controlSize(.large)
				}
				.clipShape(.circle)
				.buttonStyle(.glass)
				.controlSize(.large)
				.shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 0)
				.frame(
					maxWidth: .infinity,
					maxHeight: .infinity,
					alignment: .topLeading
				)
				.padding(.all, 50)

			}
			.onAppear { measurements = store.allMeasurements() }
		}
	}
	
	private func applyMeasurement(_ ringSize: RingSizeOption, handFinger: HandFinger) {
		store.save(
			handFinger: handFinger,
			ringSizeID: ringSize.id,
			system: bandGemViewModel.selectedRingSizeSystem,
			diameterMM: ringSize.diameterMM
		)
		bandGemViewModel.loadRingSize(
			id: ringSize.id,
			system: bandGemViewModel.selectedRingSizeSystem
		)
		reload(handFinger: handFinger)
	}
	
	private func reload(handFinger: HandFinger) {
		let currentMeasurement = store.measurement(for: handFinger)
		if let m = currentMeasurement {
			bandGemViewModel.loadRingSize(id: m.ringSizeID, system: m.ringSizeSystem)
		}
	}


}

struct HandView: View {
	let hand: Hand
	var measurement: [FingerMeasurement]
	let selectedRingSize: RingSizeSystem

	private var fingersInDrawOrder: [HandFinger] {
		hand == .left
		? [.leftpinky, .leftring, .leftmiddle, .leftpointer, .leftthumb] : [.rightthumb, .rightpointer, .rightmiddle, .rightring, .rightpinky]
	}

	private var handImage: ImageResource {
		hand == .left ? .leftHand : .rightHand
	}

	var body: some View {
		ZStack(alignment: .top) {
			Image(handImage)
				.frame(width: 450, height: 600, alignment: .bottom)
				.overlay(alignment: .bottomLeading) {
					Text(hand == .left ? "L" : "R").foregroundStyle(.secondary)
						.font(.appFont(size: 32))
						.padding(.vertical, 160)
						.padding(.horizontal, hand == .left ? 180 : 210)
				}
			HStack(alignment: .bottom, spacing: 30) {
				ForEach(fingersInDrawOrder, id: \.self) { handfinger in
					FingerButton(
						handFinger: handfinger,
						relativeHeight: relativeHeight(handfinger), measurements: measurement,
						selectedRingSize: selectedRingSize
					)
					.rotationEffect(.degrees(rotation(handfinger)))
					.offset(x: horizontalOffset(handfinger),y: verticalOffset(handfinger))
				}
			}
			.padding(.trailing, hand == .left ? 25 : -30)
			
		}

	}

	private func relativeHeight(_ handfinger: HandFinger) -> CGFloat {
		switch handfinger {
		case .leftpinky: 0.70
		case .leftring: 0.92
		case .leftmiddle: 1.0
		case .leftpointer: 0.85
		case .leftthumb: 0.70
		case .rightpinky: 0.70
		case .rightring: 0.92
		case .rightmiddle: 1.0
		case .rightpointer: 0.85
		case .rightthumb: 0.70
		}
	}
	
	private func rotation(_ handfinger: HandFinger) -> CGFloat {
		switch handfinger {
		case .leftthumb: 35
		case .rightthumb: -35
		default: 0
		}
	}
	
	private func verticalOffset(_ handfinger: HandFinger) -> CGFloat {   // NEW
			switch handfinger {
			case .leftthumb: 230
			case .rightthumb: 230
			default: 0
			}
		}
	
	private func horizontalOffset(_ handfinger: HandFinger) -> CGFloat {   // NEW
			switch handfinger {
			case .leftthumb: 10
			case .rightthumb: -10
			default: 0
			}
		}
}

struct FingerButton: View {
	let handFinger: HandFinger
	let relativeHeight: CGFloat
	var measurements: [FingerMeasurement]
	let selectedRingSize: RingSizeSystem

	var body: some View {
		NavigationLink(value: handFinger) {
			VStack(spacing: 25) {
				row(for: handFinger)
				Capsule()
					.fill(Color.clear)
					.frame(width: 58, height: 220 * relativeHeight)
					.contentShape(Capsule())
			}
		}
		.buttonStyle(.plain)
	}
	
	@ViewBuilder
	private func row(for hf: HandFinger) -> some View {
		let m = measurements.first { $0.handFinger == hf && $0.ringSizeSystem == selectedRingSize}

			VStack {
				if let m {
					HStack{
						Text(m.displaySize)
							.fontWeight(.semibold)
					}
					Text(m.diameterMM.description)
						.font(.appFont(size: 17))
						.foregroundStyle(.secondary)
				} else {
					Text("-").font(.subheadline.weight(.semibold))
				}
			}
	}

}

#Preview {
	HandSizeView()
		.environment(ViewModel())
}
