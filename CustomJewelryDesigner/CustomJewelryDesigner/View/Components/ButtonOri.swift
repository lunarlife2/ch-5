//
//  ButtonOri.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 21/08/26.
//

import SwiftUI

struct ButtonOri<Label: View>: View {
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
                .font(.appFont(size: 15, weight: .medium))
                .foregroundStyle(Color.appPrimary)
        }
        .buttonStyle(.bordered)
    }
}
