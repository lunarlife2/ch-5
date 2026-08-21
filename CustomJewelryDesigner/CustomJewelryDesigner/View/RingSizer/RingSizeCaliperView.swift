////
////  RingSizeCaliperView.swift
////  CustomJewelryDesigner
////
////  Created by Yimei Winata on 20/08/26.
////
//import SwiftUI
//
//struct Meas: View {
//
//    @State private var viewModel = RingSizerViewModel()
//
//    var body: some View {
//
//        VStack(spacing: 24) {
//
//            Text("Ukur Diameter Jari")
//                .font(.title2.bold())
//
//            Text("Tempelkan jari pada layar")
//                .foregroundStyle(.secondary)
//
//            ZStack {
//
//                // Area untuk jari user
//                FingerGuide()
//                    .frame(
//                        width: 100,
//                        height: 260
//                    )
//
//                CaliperJaws(
//                    separation: $viewModel.separationPoints,
//                    trackWidth: 280,
//                    minSeparation: viewModel.minSeparation,
//                    maxSeparation: viewModel.maxSeparation
//                )
//            }
//            .frame(height: 280)
//
//            VStack(spacing: 6) {
//
//                Text(
//                    String(
//                        format: "%.1f mm",
//                        viewModel.diameterMM
//                    )
//                )
//                .font(
//                    .system(
//                        .title,
//                        design: .rounded
//                    )
//                    .monospacedDigit()
//                )
//
//                Text(viewModel.ringSizeLabel)
//                    .font(.headline)
//            }
//
//            Button("Reset") {
//                viewModel.reset()
//            }
//        }
//        .padding()
//    }
//}
//struct FingerGuide: View {
//
//    var body: some View {
//
//        RoundedRectangle(cornerRadius: 50)
//            .stroke(
//                .secondary.opacity(0.4),
//                style: StrokeStyle(
//                    lineWidth: 2,
//                    dash: [8, 6]
//                )
//            )
//            .overlay {
//                Text("Letakkan jari di sini")
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//            }
//    }
//}
//#Preview {
//    RingSizeCaliperView()
//}
