//
//  CaliperTrack.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 23/08/26.
//

import SwiftUI

struct CaliperTrack: View {
	let hand: Hand
	let separationPoints: CGFloat
	let minSeparation: CGFloat
	let maxSeparation: CGFloat
	let onDrag: (CGFloat) -> Void

	private let cornerRadius: CGFloat = 20
	private var blueOnRight: Bool { hand == .left }
	private let dragActivationDistance: CGFloat = 12

	/// Fixed width of the draggable jaw — tune to match your design mockup.
	private let jawWidth: CGFloat = 280

	@State private var dragStartGapWidth: CGFloat?

	var body: some View {
		GeometryReader { geo in
			let trackWidth = geo.size.width
			let maxGapWidth = max(trackWidth - jawWidth, 0)
			let range = max(maxSeparation - minSeparation, 1)

			let clampedSeparation = min(max(separationPoints, minSeparation), maxSeparation)
			let fraction = (clampedSeparation - minSeparation) / range
			let gapWidth = fraction * maxGapWidth

			// Leading-edge x-position of the jaw, independent of hand mirroring.
			let jawLeadingX: CGFloat = blueOnRight
				? gapWidth
				: (trackWidth - gapWidth - jawWidth)

			ZStack(alignment: .leading) {
				Rectangle()
					.fill(Color(uiColor: .systemGray6))
					.frame(height: 294)
					.overlay(alignment: blueOnRight ? .leading : .trailing) {
						Text("Rest your \nfinger\nagainst \nthe outer ledge")
							.font(.appFont(size: 14))
							.padding(.horizontal, 2)
							.foregroundStyle(.secondary)
							.multilineTextAlignment(.center)
							.frame(width: max(gapWidth, 0))
							.opacity(gapWidth > 50 ? 1 : 0)
					}
					.allowsHitTesting(false)

				Capsule()
					.fill(Color(uiColor: .systemGray3))
					.frame(width: 20, height: 313)
					.position(
						x: blueOnRight ? -10 : trackWidth + 10,
						y: 160
					)
					.shadow(radius: 10)
					.allowsHitTesting(false)

				RoundedRectangle(cornerRadius: cornerRadius)
					.fill(Color.main)
					.frame(width: jawWidth, height: 294)
					.shadow(radius: 10, y: 10)
					.overlay(alignment: blueOnRight ? .topTrailing : .topLeading) {
						Image(systemName: "arrow.left.and.right.circle.fill")
							.font(.appFont(size: 17))
							.foregroundStyle(.white.opacity(0.9))
							.padding(10)
					}
					.overlay(alignment: .bottom) {
						Label(
							"Drag until it fits snugly",
							systemImage: "arrow.left.and.right"
						)
						.font(.appFont(size: 14))
						.foregroundStyle(.white)
						.padding(.bottom, 16)
					}
					.offset(x: jawLeadingX)
					.contentShape(Rectangle())
					.gesture(
						DragGesture(minimumDistance: dragActivationDistance)
							.onChanged { value in
								if dragStartGapWidth == nil {
									dragStartGapWidth = gapWidth
								}
								let base = dragStartGapWidth ?? gapWidth
								let delta = blueOnRight
									? value.translation.width
									: -value.translation.width

								let newGapWidth = min(max(base + delta, 0), maxGapWidth)
								let newFraction = maxGapWidth > 0 ? newGapWidth / maxGapWidth : 0
								let newSeparation = minSeparation + newFraction * range

								onDrag(newSeparation)
							}
							.onEnded { _ in
								dragStartGapWidth = nil
							}
					)
			}
		}
	}
}

//struct CaliperTrack: View {
//    let hand: Hand
//    let separationPoints: CGFloat
//    let minSeparation: CGFloat
//    let maxSeparation: CGFloat
//    let onDrag: (CGFloat) -> Void
//
//    private let cornerRadius: CGFloat = 20
//    private var blueOnRight: Bool { hand == .left }
//    private let dragActivationDistance: CGFloat = 12
//
//    var body: some View {
//        GeometryReader { geo in
//            let trackWidth = geo.size.width
//            let gapWidth = min(max(separationPoints, minSeparation), maxSeparation)
//            let blueWidth = max(trackWidth - gapWidth, 0)
//			
//			let _ = print("trackWidth: \(trackWidth), separationPoints: \(separationPoints), min: \(minSeparation), max: \(maxSeparation), gapWidth: \(gapWidth), blueWidth: \(blueWidth)")
//
//            ZStack(alignment: blueOnRight ? .trailing : .leading) {
//                Rectangle()
//                    .fill(Color(uiColor: .systemGray6))
//                    .frame(height: 294)
//                    .overlay(alignment: blueOnRight ? .leading : .trailing) {
//                        Text("Rest your \nfinger\nagainst \nthe ledge")
//                            .font(.caption)
//                            .padding(.horizontal, 2)
//                            .foregroundStyle(.secondary)
//                            .multilineTextAlignment(.center)
//                            .frame(width: max(trackWidth - blueWidth, 0))
//                            .opacity(trackWidth - blueWidth > 50 ? 1 : 0)
//                    }
//
//                Capsule()
//                    .fill(Color(uiColor: .systemGray3))
//                    .frame(width: 20, height: 313)
//                    .shadow(radius: 10)
//                    .position(
//                        x: blueOnRight ? -10 : 360,
//                        y: 160
//                    )
//
//                RoundedRectangle(cornerRadius: cornerRadius)
//					.fill(Color.blue)
//                    .frame(width: blueWidth, height: 294)
//                    .shadow(radius: 10, y: 10)
//                    .overlay(alignment: blueOnRight ? .topTrailing : .topLeading) {
//                        Image(systemName: "arrow.left.and.right.circle.fill")
//                            .font(.title3)
//                            .foregroundStyle(.white.opacity(0.9))
//                            .padding(10)
//                    }
//                    .overlay(alignment: .bottom) {
//                        Label(
//                            "Drag until it fits snugly",
//                            systemImage: "arrow.left.and.right"
//                        )
//                        .font(.caption)
//                        .foregroundStyle(.white)
//                        .padding(.bottom, 16)
//                    }
//            }
//            .contentShape(Rectangle())
//            .gesture(
//                DragGesture(minimumDistance: dragActivationDistance)
//                    .onChanged { value in
//                        let x = value.location.x
//
//                        let newSeparation = blueOnRight
//                            ? x
//                            : (trackWidth - x)
//
//                        onDrag(newSeparation)
//                    }
//            )
//        }
//    }
//}
