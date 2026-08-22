//
//  SkinView.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 21/08/26.
//

import SwiftUI

struct SkinView: View {
    @State private var isSelectedPresets = true
    @State private var showCamera = false
    
    var body: some View {
        VStack {
            matchWithCameraButton
            
            Divider()
            
            VStack {
                Text("Presets")
                    .font(.system(size: 16, weight: .semibold))
                
                HStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 26, height: 26)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelectedPresets ? Color.gray : Color.clear,
                                    lineWidth: isSelectedPresets ? 1 : 0
                                )
                        )
                }
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
            .padding(.horizontal, 14).padding(.vertical, 12)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.glassProminent)
    }
}

#Preview {
    SkinView()
}
