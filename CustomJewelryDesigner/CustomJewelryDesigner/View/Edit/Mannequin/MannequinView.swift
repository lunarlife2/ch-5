//
//  MannequinView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 18/08/26.
//

import SwiftUI

struct MannequinView: View {
    @State private var selectedFinger: Finger = .thumb
    @State private var showColorPicker = false
    var viewModel: EditViewModel
    
    var body: some View {
        VStack {
            //choose finger
            VStack {
                Text("Choose Finger")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 30)
                
                Picker("", selection: $selectedFinger) {
                    ForEach(Finger.allCases) { system in
                        Text(system.title)
                            .tag(system)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            //choose skin color
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose Skin Color")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 30)

                skinColorButton
                    .padding(.horizontal, 30)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showColorPicker) {
            SkinColorPickerView(
                initialColor: viewModel.skinColor,
                onPreview: { color in
                    viewModel.setSkinColor(color)
                },
                onApply: { color in
                    viewModel.setSkinColor(color)
                }
            )
        }
    }
    
    private var skinColorButton: some View {
        Button {
            showColorPicker = true
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(viewModel.skinColor)
                    .overlay(Circle().strokeBorder(Color.black.opacity(0.08)))
                    .frame(width: 32, height: 32)

                Text("#\(viewModel.skinColor.hexString)")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

//#Preview {
//    MannequinView()
//        .environment(
//            EditViewModel(
//                designFile: DesignFile(
//                    id: UUID(),
//                    name: "Preview",
//                    updatedAt: .now,
//                    ringPosition: .left,
//                    design: nil
//                )
//            )
//        )
//}
