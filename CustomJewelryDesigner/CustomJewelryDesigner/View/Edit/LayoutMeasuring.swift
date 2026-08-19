//
//  LayoutMeasuring.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 19/08/26.
//

import SwiftUI

struct TopBarHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(
        value: inout CGFloat,
        nextValue: () -> CGFloat
    ) {
        value = max(value, nextValue())
    }
}

struct BottomControlsHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(
        value: inout CGFloat,
        nextValue: () -> CGFloat
    ) {
        value = max(value, nextValue())
    }
}

extension View {
    func reportHeight<K: PreferenceKey>(
        _ key: K.Type
    ) -> some View where K.Value == CGFloat {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: key,
                        value: proxy.size.height
                    )
            }
        )
    }
}
