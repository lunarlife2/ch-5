//
//  HandProfileView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 23/08/26.
//

import SwiftUI

struct HandProfileView: View {
    let store: HandProfileStore
    var onSelectFinger: (HandFinger) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var measurements: [FingerMeasurement] = []

    var body: some View {
        NavigationStack {
            List {
                Section("Left Hand") {
                    ForEach(HandFinger.allCases.filter { $0.hand == .left }) { hf in
                        row(for: hf)
                    }
                }
                Section("Right Hand") {
                    ForEach(HandFinger.allCases.filter { $0.hand == .right }) { hf in
                        row(for: hf)
                    }
                }
            }
            .navigationTitle("Hand Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { measurements = store.allMeasurements() }
        }
    }

    @ViewBuilder
    private func row(for hf: HandFinger) -> some View {
        let m = measurements.first { $0.handFinger == hf }

        Button {
            onSelectFinger(hf)
        } label: {
            HStack {
                Text(hf.finger.title)
                Spacer()
                if let m {
                    Text(m.displaySize)
                        .fontWeight(.semibold)
                    Text(m.ringSizeSystem.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Not measured")
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}
