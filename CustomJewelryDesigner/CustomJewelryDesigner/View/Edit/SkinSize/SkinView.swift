//
//  SkinView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 21/08/26.
//

import SwiftUI

struct SkinView: View {
    @Bindable private var recentSkinColorStore = RecentSkinColorStore.shared
    
    @State private var showCamera = false

    @State private var selectedSkinColorID: Int?
    @State private var selectedPresetID: Int?
    @State private var selectedRecentColorHex: String?
    
    @State private var color: Color
    @State private var hexText: String

    var onPreview: (Color) -> Void
    var editViewModel: EditViewModel

    init(initialColor: Color, onPreview: @escaping (Color) -> Void, editViewModel: EditViewModel) {
        self.onPreview = onPreview
        self.editViewModel = editViewModel

        _color = State(initialValue: initialColor)
        _hexText = State(initialValue: initialColor.hexString)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            matchWithCameraButton

            if !filteredRecentColors.isEmpty {
                recentlyMatchedSection
            }

            Divider()

            presetsSection
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .fullScreenCover(isPresented: $showCamera) {
            SkinToneCameraView(
                onFinish: { matched in
                    color = matched
                    hexText = matched.hexString
                    
                    editViewModel.setSkinColor(matched)
                    onPreview(matched)
                }
            )
        }
    }
    
    private var filteredRecentColors: [Color] {
        recentSkinColorStore.recentColors.filter { recentColor in
            !skinColorPresets.contains { preset in
                Color(hex: preset.color).hexString == recentColor.hexString
            }
        }
    }

    private var matchWithCameraButton: some View {
        Button {
            showCamera = true
        } label: {
            HStack {
                Image(systemName: "camera.fill")
                Text("Match with Camera")
            }
            .font(.system(size: 15, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.glassProminent)
    }
    
    private var recentlyMatchedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recently Matched")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                ForEach(filteredRecentColors, id: \.hexString) { recentColor in
                    Button {
                        selectedRecentColorHex = recentColor.hexString
                        selectedPresetID = nil

                        color = recentColor
                        hexText = recentColor.hexString

                        editViewModel.setSkinColor(recentColor)
                        onPreview(recentColor)
                    } label: {
                        Circle()
                            .fill(recentColor)
                            .frame(width: 26, height: 26)
                            .padding(4)
                            .overlay {
                                Circle()
                                    .stroke(
                                        selectedRecentColorHex == recentColor.hexString
                                            ? Color.gray
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Presets")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                ForEach(skinColorPresets) { preset in
                    Button {
                        let newColor = Color(hex: preset.color)

                        selectedPresetID = preset.id
                        selectedRecentColorHex = nil

                        color = newColor
                        hexText = newColor.hexString

                        editViewModel.setSkinColor(newColor)
                        onPreview(newColor)
                    } label: {
                        Circle()
                            .fill(Color(hex: preset.color))
                            .frame(width: 26, height: 26)
                            .padding(4)
                            .overlay {
                                Circle()
                                    .stroke(
                                        selectedPresetID == preset.id
                                            ? Color.gray
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
