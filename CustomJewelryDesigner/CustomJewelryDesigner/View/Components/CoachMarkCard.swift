//
//  CoachMarkCard.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 24/08/26.
//
import SwiftUI

struct CoachMarkCard: View {
    var title: String
    var subtitle: String
    var stepInfo: (index: Int, total: Int)? = nil
    var onSkip: () -> Void
    var onNext: (() -> Void)? = nil
    var nextLabel: String = "Got It"

    var width: CGFloat = 360
    var height: CGFloat? = 200

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()

                if let stepInfo {
                    Text("\(stepInfo.index) of \(stepInfo.total)")
                        .font(.appFont(size: 17))
                        .foregroundStyle(.secondary)
                }

                Button {
                    onSkip()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.appPrimary)
                }
            }

            Text(title)
                .font(.appFont(size: 24))

            Text(subtitle)
                .font(.appFont(size: 17))
                .foregroundStyle(.secondary)

            if let onNext {
                Button(nextLabel, action: onNext)
                    .tint(Color.appPrimary)
                    .buttonStyle(.glassProminent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
        .padding(16)
        .frame(width: width, height: height)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(radius: 12)
        }
    }
}
