//
//  DetailView.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import SwiftUI
import SwiftData

struct DetailView: View {
    @Environment(ViewModel.self) private var vm
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var designFile: DesignFile

    @State private var notes: String
    @State private var size: Double
    @State private var showSizeGuide = false
    @State private var selectedAngle: RingAngle = .front
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @State private var isPreparingShare = false

    enum RingAngle: Int, CaseIterable, Identifiable {
        case front, back, right, left
        var id: Int { rawValue }
        var label: String {
            switch self {
            case .front: return "Front"
            case .back: return "Back"
            case .right: return "Right"
            case .left: return "Left"
            }
        }
    }

    init(designFile: DesignFile) {
        self.designFile = designFile
        _notes = State(initialValue: designFile.notes ?? "")
        _size = State(initialValue: Self.usRingSize(for: designFile) ?? 7.0)
    }


    private var design: Design? { designFile.design }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: designFile.updatedAt)
    }

    private var metalText: String { design?.band?.material ?? "Not selected yet" }

    private func gemDisplayName(for gem: GemComponent) -> String {
        let material = gem.color?.capitalized
        let shape = gem.cut?.capitalized

        switch (material, shape) {
        case let (material?, shape?):
            return "\(material) \(shape)"
        case let (material?, nil):
            return material
        case let (nil, shape?):
            return shape
        default:
            return "Gem"
        }
    }

    private var gemText: String {
        let names = design?.gems.map { gemDisplayName(for: $0) } ?? []
        return names.isEmpty ? "No gem added" : names.joined(separator: ", ")
    }

    private var thicknessText: String { design?.band?.thickness?.capitalized ?? "Not selected yet" }

    private var metalColor: Color {
        let text = metalText.lowercased()
        if text.contains("white gold") || text.contains("platinum") {
            return Color(red: 0.85, green: 0.86, blue: 0.88)
        } else if text.contains("yellow gold") {
            return Color(red: 0.95, green: 0.80, blue: 0.35)
        } else if text.contains("rose gold") {
            return Color(red: 0.90, green: 0.70, blue: 0.65)
        }
        return Color(.systemGray4)
    }

    private var gemColor: Color {
        let text = (design?.gems.first?.color ?? design?.gems.first?.name ?? "").lowercased()
        if text.contains("morganite") { return Color(red: 0.95, green: 0.80, blue: 0.82) }
        if text.contains("sapphire") { return Color(red: 0.25, green: 0.41, blue: 0.88) }
        if text.contains("ruby") { return Color(red: 0.72, green: 0.09, blue: 0.19) }
        if text.contains("emerald") { return Color(red: 0.0, green: 0.44, blue: 0.24) }
        if text.contains("diamond") { return Color(white: 0.95) }
        return Color(.systemGray4)
    }

    private func imageData(for angle: RingAngle) -> Data? {
        switch angle {
        case .front: return designFile.thumbnailData
        case .back: return designFile.backImageData
        case .right: return designFile.rightImageData
        case .left: return designFile.leftImageData
        }
    }

    private func fallbackAsset(for angle: RingAngle) -> ImageResource {
        switch angle {
        case .front: return .detail34
        case .back: return .detailTop
        case .right: return .detailRight
        case .left: return .detailLeft
        }
    }

    private func image(for angle: RingAngle) -> Image {
        if let data = imageData(for: angle), let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return Image(fallbackAsset(for: angle))
    }

    private static func usRingSize(for designFile: DesignFile) -> Double? {
        guard let id = designFile.design?.ringSizeID,
              let option = ringSizeOptions.first(where: { $0.id == id }),
              let value = Double(option.usCanada) else {
            return nil
        }
        return value
    }

    private func closestRingSizeOption(for value: Double) -> RingSizeOption? {
        ringSizeOptions.min { lhs, rhs in
            let lhsValue = Double(lhs.usCanada) ?? .infinity
            let rhsValue = Double(rhs.usCanada) ?? .infinity
            return abs(lhsValue - value) < abs(rhsValue - value)
        }
    }


    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white.ignoresSafeArea()

            ScrollView {
                card
                    .padding(32)
            }

            backButton
                .padding(24)
        }
        .sheet(isPresented: $showSizeGuide) { sizeGuideSheet }
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ShareSheet(activityItems: [shareURL])
            }
        }
    }

    private var backButton: some View {
        Button {
            vm.moveScreenState(to: .edit(designFile))
        } label: {
            Image(systemName: "chevron.left")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(width: 36, height: 36)
                .background(Color.white, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var card: some View {
        HStack(alignment: .top, spacing: 32) {
            imagePanel
            infoPanel
        }
        .padding(32)
//        .background(
//            RoundedRectangle(cornerRadius: 28, style: .continuous)
//                .fill(Color.white)
//                .shadow(color: .black.opacity(0.08), radius: 24, y: 10)
//        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var imagePanel: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                image(for: selectedAngle)
                    .resizable()
                    .scaledToFit()
                    .padding(24)
                    .frame(width: 400, height: 420)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.systemGray6))
                    )

                Text("\(selectedAngle.rawValue + 1)/\(RingAngle.allCases.count)")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.55), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(16)
            }

            HStack(spacing: 12) {
                ForEach(RingAngle.allCases) { angle in
                    thumbnailButton(for: angle)
                }
            }
        }
        .frame(width: 500)
    }

    private func thumbnailButton(for angle: RingAngle) -> some View {
        Button {
            withAnimation(.snappy) { selectedAngle = angle }
        } label: {
            VStack(spacing: 6) {
                image(for: angle)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .frame(width: 100, height: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selectedAngle == angle ? Color.black : .clear, lineWidth: 2)
                    )

                Text(angle.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(designFile.name)
                        .font(.title2.weight(.semibold))
                    Text(dateText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showSizeGuide.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 16) {
                infoRow(label: "Metal", value: metalText, swatch: metalColor)
                infoRow(label: "Gem", value: gemText)
                infoRow(label: "Band Thickness", value: thicknessText)
                sizeRow
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                TextField("Type your notes here", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
            }

            actionButtons
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func infoRow(label: String, value: String, swatch: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 130, alignment: .leading)

            Text(value)
                .font(.subheadline.weight(.medium))

            Spacer()

            if let swatch {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(swatch)
                    .frame(width: 30, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
            }
        }
    }

    private var sizeRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Size Checker")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 130, alignment: .leading)

                Text("US \(size, format: .number.precision(.fractionLength(1)))")
                    .font(.subheadline.weight(.medium))

                Spacer()
            }

        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                saveAndReturnHome()
            } label: {
                Text("Save")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 110, height: 42)
            }
            .buttonStyle(.plain)
            .background(Color.black, in: Capsule())

            Button {
                prepareAndShare()
            } label: {
                HStack(spacing: 6) {
                    if isPreparingShare {
                        ProgressView().controlSize(.small)
                    }
                    Text("Share")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.black)
                .frame(width: 110, height: 42)
            }
            .buttonStyle(.plain)
            .background(Color(.systemGray6), in: Capsule())
            .overlay(Capsule().stroke(Color.black.opacity(0.1), lineWidth: 1))
            .disabled(isPreparingShare)
        }
        .padding(.top, 4)
    }

    private var sizeGuideSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                    ForEach(ringSizes) { ringSize in
                        Text(ringSize.size)
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding()
            }
            .navigationTitle("Ring Size Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showSizeGuide = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveAndReturnHome() {
        designFile.notes = notes

        if let option = closestRingSizeOption(for: size) {
            design?.ringSizeID = option.id
            if design?.ringSizeSystem == nil {
                design?.ringSizeSystem = .usCanada
            }
        }

        designFile.updatedAt = .now

        do {
            try modelContext.save()
        } catch {
            print("Failed to save design file details: \(error)")
        }

        vm.moveScreenState(to: .home)
    }

    private func prepareAndShare() {
        // save notes to DesignFile
        designFile.notes = notes

        // save to SwiftData
        do {
            try modelContext.save()
        } catch {
            print("Failed to save notes before sharing: \(error)")
        }

        isPreparingShare = true

        Task {
            let url = OrderSheetPDFExporter.makePDF(for: designFile)

            isPreparingShare = false

            if let url {
                shareURL = url
                showShareSheet = true
            }
        }
    }
}
