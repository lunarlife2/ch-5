//
//  SizeView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 14/08/26.
//

import SwiftUI
import SwiftData

struct SizeView: View {
    @Environment(ViewModel.self) private var vm
    @Environment(\.modelContext) private var modelContext

    @State private var currentMeasurement: FingerMeasurement?
    @State private var showMeasureView = false
    @State private var showHandProfile = false

    @Bindable var bandGemViewModel: BandGemViewModel
    var editViewModel: EditViewModel

    private var store: HandProfileStore { HandProfileStore(modelContext: modelContext) }

    var body: some View {
        VStack(spacing: 20) {
            Menu {
                ForEach(HandFinger.allCases) { hf in
                    Button {
                        bindingToHandFinger.wrappedValue = hf
                    } label: {
                        HStack {
                            Text(hf.title)

                            if hf == bindingToHandFinger.wrappedValue {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .disabled(!editViewModel.scene.isPlacementAvailable(for: hf))
                }
            } label: {
                HStack {
                    Text(bindingToHandFinger.wrappedValue.title)
                        .foregroundStyle(Color.black)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                }
                .foregroundStyle(Color.handFingerPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.handFingerPrimary.opacity(0.12))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.handFingerPrimary.opacity(0.35), lineWidth: 1)
            }
            .glassEffect()

            if let m = currentMeasurement {
                measuredCard(m)
            } else {
                notMeasuredCard
            }

            Button {
                showHandProfile = true
            } label: {
                Text("View Full Hand Profile")
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .task(id: editViewModel.selectedHandFinger) {
            reload()
        }
        .fullScreenCover(isPresented: $showHandProfile) {
            HandProfileView(store: store) { tappedFinger in
                showHandProfile = false
                editViewModel.selectedHandFinger = tappedFinger
                showMeasureView = true
            }
        }
    }

    private func measuredCard(_ m: FingerMeasurement) -> some View {
        VStack {
            HStack {
                Text(m.displaySize)
                    .font(.system(size: 34, weight: .black))
                Spacer()
                Button {
                    bandGemViewModel.selectedRingSizeSystem = m.ringSizeSystem
                    showMeasureView = true
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.glass)
            }

            Picker("", selection: $bandGemViewModel.selectedRingSizeSystem) {
                ForEach(RingSizeSystem.allCases) { system in
                    Text(system.title)
                        .tag(system)
                }
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: bandGemViewModel.selectedRingSizeSystem) { _, newSystem in
                guard let option = m.ringSizeOption,
                      option.size(for: newSystem) != nil else { return }
                store.save(
                    handFinger: m.handFinger,
                    ringSizeID: option.id,
                    system: newSystem,
                    diameterMM: m.diameterMM
                )
                reload()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray).opacity(0.6)
        )
        .fullScreenCover(isPresented: $showMeasureView) {
            MeasureView(
                bandGemViewModel: bandGemViewModel,
                handFinger: m.handFinger,
                hand: editViewModel.selectedHandFinger.hand,
                initialMeasurement: m,
                onBack: { showMeasureView = false },
                onApply: { ringSize in
                    applyMeasurement(ringSize)
                }
            )
        }
    }

    private var notMeasuredCard: some View {
        VStack {
            Text("Not Measured yet")
                .frame(maxWidth: .infinity, minHeight: 113)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.6))
                )

            Button {
                showMeasureView = true
            } label: {
                Text("Measure This Finger")
                    .frame(maxWidth: .infinity)
                    .padding(8)
            }
            .buttonStyle(.glassProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
        .fullScreenCover(isPresented: $showMeasureView) {
            MeasureView(
                bandGemViewModel: bandGemViewModel,
                handFinger: editViewModel.selectedHandFinger,
                hand: editViewModel.selectedHandFinger.hand,
                initialMeasurement: nil,
                onBack: { showMeasureView = false },
                onApply: { ringSize in
                    applyMeasurement(ringSize)
                }
            )
        }
    }

    private func applyMeasurement(_ ringSize: RingSizeOption) {
        store.save(
            handFinger: editViewModel.selectedHandFinger,
            ringSizeID: ringSize.id,
            system: bandGemViewModel.selectedRingSizeSystem,
            diameterMM: ringSize.diameterMM
        )
        bandGemViewModel.loadRingSize(
            id: ringSize.id,
            system: bandGemViewModel.selectedRingSizeSystem
        )
        reload()
    }

    private func reload() {
        currentMeasurement = store.measurement(for: editViewModel.selectedHandFinger)
        if let m = currentMeasurement {
            bandGemViewModel.loadRingSize(id: m.ringSizeID, system: m.ringSizeSystem)
        }
    }

    private var bindingToHandFinger: Binding<HandFinger> {
        Binding(
            get: { editViewModel.selectedHandFinger },
            set: { newValue in
                guard editViewModel.scene.isPlacementAvailable(for: newValue) else { return }
                editViewModel.selectedHandFinger = newValue
            }
        )
    }
}
