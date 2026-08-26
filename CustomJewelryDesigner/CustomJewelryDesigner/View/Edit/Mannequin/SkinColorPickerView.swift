//
//  SkinColorPickerView.swift
//  CustomJewelryDesigner
//
//  Created by Ni Komang Ayu Juliana on 21/08/26.
//

import SwiftUI

struct SkinColorPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let initialColor: Color
    var onPreview: (Color) -> Void
    var onApply: (Color) -> Void     

    @State private var color: Color
    @State private var hexText: String
    @State private var showCamera = false

    init(initialColor: Color, onPreview: @escaping (Color) -> Void, onApply: @escaping (Color) -> Void) {
        self.initialColor = initialColor
        self.onPreview = onPreview
        self.onApply = onApply
        _color = State(initialValue: initialColor)
        _hexText = State(initialValue: initialColor.hexString)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ColorSquarePickerView(color: $color)
                        .onChange(of: color) { _, newValue in
                            hexText = newValue.hexString
                            onPreview(newValue)
                        }

                    hexAndSwatchRow
                    matchWithCameraButton
                    RecentlyMatchedRow(selectedColor: color) { color = $0 }
                }
                .padding(20)
            }
            .navigationTitle("Choose Skin Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        RecentSkinColorStore.shared.record(color)
                        onApply(color)
                        dismiss()
                    }.fontWeight(.semibold)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                SkinToneCameraView(
                    onFinish: { matched in
                    color = matched
                    hexText = matched.hexString
                    onPreview(matched)
                }
                
                )
            }
        }
    }

    private var hexAndSwatchRow: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10).fill(color).frame(width: 44, height: 44)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.black.opacity(0.1)))

            HStack(spacing: 4) {
                Text("#").foregroundStyle(.secondary)
                TextField("HEX", text: $hexText)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .onSubmit(applyHexText)
                    .onChange(of: hexText) { _, newValue in
                        let filtered = String(newValue.uppercased().filter { $0.isHexDigit })
                        if filtered != newValue { hexText = filtered }
                        if filtered.count == 6 { applyHexText() }
                    }
            }
            .font(.appFont(size: 16, weight: .medium, design: .monospaced))
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer()
        }
    }

    private func applyHexText() {
        guard hexText.count == 6 else { return }
        let newColor = Color(hex: hexText)
        color = newColor
        onPreview(newColor)
    }

    private var matchWithCameraButton: some View {
        Button { showCamera = true } label: {
            HStack {
                Image(systemName: "camera.fill")
                Text("Match with Camera")
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .font(.appFont(size: 15, weight: .semibold))
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
