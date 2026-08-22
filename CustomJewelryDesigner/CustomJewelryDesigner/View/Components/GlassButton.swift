//
//  BackButton.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 13/08/26.
//

import SwiftUI

struct GlassButton<Label: View>: View {
    private let action: () -> Void
    private let label: () -> Label
    
    init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            label()
                .foregroundStyle(Color.black)
                .font(.system(size: 27, weight: .medium))
                .frame(width: 20, height: 30)
        }
        .buttonStyle(.glassProminent)
        .tint(.white)
        .shadow(color: Color.shadowSecondary, radius: 0.25, x: 1.25)
        .shadow(color: Color.shadowSecondary, radius: 0.25, x: -1.25)
        .shadow(color: Color.shadowTertiary, radius: 0.5)
        .shadow(color: .black.opacity(0.02), radius: 15, y: 8)
    }
}
