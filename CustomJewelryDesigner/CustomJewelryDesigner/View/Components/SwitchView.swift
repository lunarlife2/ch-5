//
//  SwitchView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 13/08/26.
//

import SwiftUI

struct SwitchView: View {
    @State private var selectedMode: JewelryEditorMode = .band
    @Bindable var viewModel: EditViewModel
    
    var body: some View {
        Picker("Category", selection: $viewModel.mode) {
            ForEach(JewelryEditorMode.allCases) { mode in
                if let catUIImage = ImageRenderer(
                    content: buildCategoryView(mode: mode)
                        
                ).uiImage {
                    Image(uiImage: catUIImage)
                        .tag(mode)
                }
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 100)
    }
    
    private func buildCategoryView(mode: JewelryEditorMode) -> some View {
        HStack {
            if mode.isSystemImage {
                Image(systemName: mode.image)
            } else {
                Image(mode.image)
            }
            Text(mode.title)
        }
    }
}

#Preview {
    @Previewable @State var viewModel = EditViewModel()
    
    SwitchView(viewModel: viewModel)
}
