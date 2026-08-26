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
    var pendingActionHint: String? = nil
    
    var width: CGFloat = 300
    var height: CGFloat? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                if let stepInfo {
                    Text("\(stepInfo.index) of \(stepInfo.total)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button { onSkip() } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.appPrimary)
                }
            }
            
            Text(title).font(.headline)
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            
            if let onNext {
                Button(nextLabel, action: onNext)
                    .tint(Color.appPrimary)
                    .buttonStyle(.glassProminent)
                    .frame(maxWidth: .infinity, alignment: .bottomTrailing)
                    .padding(.vertical, 10)
            } else if let pendingActionHint {
                Text(pendingActionHint)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .padding(.vertical, 8)
        .frame(width: width, height: height)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(radius: 12)
        }
    }
}
