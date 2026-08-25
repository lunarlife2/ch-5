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
	@Query private var savedSizes: [SavedRingSize]

	private func saved(for handFinger: HandFinger) -> SavedRingSize? {
		savedSizes.first { $0.handFinger == handFinger }
	}

	var body: some View {
		NavigationStack {
			ZStack {
				VStack {
					Text("Hand Profile")
						.font(.title)
					Text(
						"Save your measurements and tone for quick virtual try-ons."
					)
					.font(.system(size: 17, weight: .regular))
					.foregroundStyle(Color.gray)

					Spacer()

					Text("Tap a finger to add or edit a size")
						.font(.system(size: 17, weight: .regular))
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
						HandView(hand: .left, sizeFor: saved(for:))
						HandView(hand: .right, sizeFor: saved(for:))
					}
					.frame(maxHeight: .infinity, alignment: .bottom)
				}
				.navigationDestination(for: HandFinger.self) { handFinger in
					MeasureView(
						bandGemViewModel: bandGemViewModel,
						hand: handFinger.hand,
						handFinger: handFinger
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
		}
	}
}

struct HandView: View {
	let hand: Hand
	let sizeFor: (HandFinger) -> SavedRingSize?

	private var fingersInDrawOrder: [Finger] {
		hand == .left
		? [.pinky, .ring, .middle, .index, .thumb] : [.thumb, .index, .middle, .ring, .pinky]
	}

	private var handImage: ImageResource {
		hand == .left ? .leftHand : .rightHand
	}

	var body: some View {
		ZStack(alignment: .top) {
			Image(handImage)
				.frame(width: 450, height: 580, alignment: .bottom)
				.overlay(alignment: .bottomLeading) {
					Text(hand == .left ? "L" : "R").foregroundStyle(.secondary)
						.font(.system(size: 32))
						.padding(.vertical, 160)
						.padding(.horizontal, hand == .left ? 180 : 210)
				}
			HStack(alignment: .bottom, spacing: 30) {
				ForEach(fingersInDrawOrder, id: \.self) { finger in
					let handFinger = HandFinger.from(hand: hand, finger: finger)
					FingerButton(
						handFinger: handFinger,
						saved: sizeFor(handFinger),
						relativeHeight: relativeHeight(finger)
					)
					.rotationEffect(.degrees(hand == .left ? rotation(finger) : -rotation(finger)))
					.offset(x: hand == .left ? horizontalOffset(finger) : -horizontalOffset(finger),y: verticalOffset(finger))
				}
			}
			.padding(.trailing, hand == .left ? 25 : -30)
			
		}

	}

	private func relativeHeight(_ finger: Finger) -> CGFloat {
		switch finger {
		case .pinky: 0.70
		case .ring: 0.92
		case .middle: 1.0
		case .index: 0.85
		case .thumb: 0.70
		}
	}
	
	private func rotation(_ finger: Finger) -> CGFloat {
		switch finger {
		case .thumb: 35
		default: 0
		}
	}
	
	private func verticalOffset(_ finger: Finger) -> CGFloat {   // NEW
			switch finger {
			case .thumb: 230
			default: 0
			}
		}
	
	private func horizontalOffset(_ finger: Finger) -> CGFloat {   // NEW
			switch finger {
			case .thumb: 10
			default: 0
			}
		}
}

struct FingerButton: View {
	let handFinger: HandFinger
	let saved: SavedRingSize?
	let relativeHeight: CGFloat

	var body: some View {
		NavigationLink(value: handFinger) {
			VStack(spacing: 15) {
				labelStack
				Capsule()
					.fill(Color.clear)
					.frame(width: 58, height: 220 * relativeHeight)
					.contentShape(Capsule())
			}
		}
		.buttonStyle(.plain)
	}

	@ViewBuilder
	private var labelStack: some View {
		// saved.sizeID -> display string depends on RingSizeOption.size(for:);
		// resolve it the same way your BandGemViewModel does.
		if let saved,
			let option = ringSizeOptions.first(where: { $0.id == saved.sizeID })
		{
			Text(option.size(for: saved.system)?.description ?? "-")
				.font(.subheadline.weight(.semibold))
		} else {
			Text("-").font(.subheadline.weight(.semibold))
		}
	}
}

#Preview {
	HandSizeView()
		.environment(ViewModel())
}
