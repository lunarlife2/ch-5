//
//  EditViewModel.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import Foundation
import SwiftUI
import RealityKit
import SwiftData
import simd
import Supabase

enum JewelryEditorMode: String, CaseIterable, Identifiable {
    case band
    case handMannequin

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .band:
            return "Ring View"
        case .handMannequin:
            return "Hand View"
        }
    }

    var image: String {
        switch self {
        case .band:
            return "ring_view"
        case .handMannequin:
            return "hand.raised"
        }
    }

    var isSystemImage: Bool {
        switch self {
        case .band:
            return false
        case .handMannequin:
            return true
        }
    }
}

@MainActor
@Observable
final class EditViewModel {
    let scene = JewelrySceneController()
    
    private let persistence = DesignPersistenceService()
    private(set) var designFile: DesignFile
    private var modelContext: ModelContext?

    var mode: JewelryEditorMode = .band {
        didSet { scene.updateVisibility(for: mode) }
    }
    
    //connecting to supabase
    var bands: [Band] = []
    var gems: [Gem] = []
    var bandStyles: [BandStyle] = []
    var selectedBand: Band?
    var isLoading = false
    var isBandUpdating = false
    var isLoadingAsset = false
    var errorMessage: String?
    var selectedGizmoAxis: ViewAxis?
    
    private(set) var currentBand: Band?
    private(set) var isGemSelected = false
    
    //position of three button
    private var selectedGemButtonAnchor: CGPoint?
    
    //trash button
    private(set) var selectedGemTrashPosition: CGPoint?
    
    //rotate button
    private(set) var selectedGemRotatePosition: CGPoint?
    
    //button scale
    private(set) var selectedGemScalePosition: CGPoint?
    private var scaleDragStartLocalScale: SIMD3<Float>?
    private let scaleDragSensitivity: Float = 0.01
    private let scaleFactorMin: Float = 0.2
    private let scaleFactorMax: Float = 5.0

    private func distinctPreservingOrder(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for value in values where !seen.contains(value) {
            seen.insert(value)
            result.append(value)
        }
        return result
    }

    var bandThicknessOptions: [String] {
        distinctPreservingOrder(bands.map { $0.bandThickness })
    }

    var gemShapeOptions: [String] {
        distinctPreservingOrder(gems.map { $0.gemShape })
    }

    var gemMaterialOptions: [String] {
        distinctPreservingOrder(gems.map { $0.gemMaterial })
    }

    var defaultBandStyle: BandStyle? { bandStyles.first }
    var defaultBandThickness: String? { bandThicknessOptions.first }
    var defaultGemShape: String? {
        gemShapeOptions.first { $0.caseInsensitiveCompare("oval") == .orderedSame }
            ?? gemShapeOptions.first
    }
    var defaultGemMaterial: String? {
        gemMaterialOptions.first { $0.caseInsensitiveCompare("silver") == .orderedSame }
            ?? gemMaterialOptions.first
    }
    private(set) var hasUnsavedChanges = false
    private(set) var selectedGemName: String?
    private(set) var pendingDeleteGemName: String?
    var liveDragGlobalPoint: CGPoint?
    private(set) var editorFrameInGlobal: CGRect = .zero
    private(set) var trashFrameInGlobal: CGRect = .zero
    private var pendingBandAssetPath: String = "Flat_Band_Ring"
    private var pendingBandName: String = "plain band usd"

    private let snapScreenRadius: CGFloat = 50
    private let tapAlignRadius: Float = 0.0025

    var design: Design? {
        designFile.design
    }

    init(designFile: DesignFile) {
        self.designFile = designFile
    }

    func setDesignFile(_ file: DesignFile) {
        self.designFile = file
    }
    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }
    func setRealityContent(_ content: RealityViewCameraContent) {
        scene.setRealityContent(content)
    }

    func setEditorFrame(_ frame: CGRect) {
        editorFrameInGlobal = frame
        scene.setEditorFrame(frame)
    }
    func isInsideEditor(_ globalPoint: CGPoint) -> Bool {
        editorFrameInGlobal.contains(globalPoint)
    }
    func setTrashFrame(_ frame: CGRect) {
        trashFrameInGlobal = frame
    }
    func isOverTrash(_ globalPoint: CGPoint) -> Bool {
        trashFrameInGlobal.contains(globalPoint)
    }
    func markDirty() {
        hasUnsavedChanges = true
    }
    func clearDirty() {
        hasUnsavedChanges = false
    }
    func selectGem(_ gem: Entity) {
        selectedGemName = gem.name
        if gem.components[GestureComponent.self]?.typeJewelry == .gemstone {
            isGemSelected = true
        }
    }
    func clearSelection() {
        selectedGemName = nil
    }
    func requestDelete(for gem: Entity) {
        selectedGemName = gem.name
        pendingDeleteGemName = gem.name
    }
    func cancelPendingDelete() {
        pendingDeleteGemName = nil
    }
    func confirmPendingDelete() {
        guard let name = pendingDeleteGemName else { return }
        selectedGemName = name
        delete()
        pendingDeleteGemName = nil
    }

    func fetchBands() async {
        do {
            let bands: [Band] = try await supabase
                .from("ms_band")
                .select("""
                    band_id,
                    description,
                    band_thickness,
                    band_material,
                    asset_id(*),
                    band_style_id(*)
                """)
                .execute()
                .value
            self.bands = bands
            print("Band count:", bands.count)
        } catch {
            print(error)
            self.errorMessage = "Gagal memuat data band: \(error.localizedDescription)"
        }
    }
        
    func fetchGems() async {
        do {
            let gems: [Gem] = try await supabase
                .from("ms_gem")
                .select("""
                    gem_id,
                    gem_shape,
                    gem_material,
                    asset_id(*)
                """)
                .execute()
                .value

            self.gems = gems
            print("Gem count:", gems.count)
        } catch {
            print(error)
        }
    }

    func fetchBandStyles() async {
        do {
            let bandStyles: [BandStyle] = try await supabase
                .from("ms_band_style")
                .select("""
                    band_style_id,
                    band_style_name,
                    band_style_description
                """)
                .execute()
                .value

            self.bandStyles = bandStyles
            print("BandStyle count:", bandStyles.count)
        } catch {
            print(error)
        }
    }

    func fetchAllData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        async let bandsTask: () = fetchBands()
        async let gemsTask: () = fetchGems()
        async let bandStylesTask: () = fetchBandStyles()

        _ = await (bandsTask, gemsTask, bandStylesTask)
    }
    
    //fetch 3d data on supabase storage
    func getModelURL(path: String, bucket: String) async -> URL? {
        do {
            return try await supabase.storage
                .from(bucket)
                .createSignedURL(path: path, expiresIn: 3600 * 100)
        } catch {
            print("Gagal mendapatkan URL untuk \(path) di bucket \(bucket): \(error)")
            return nil
        }
    }
    
    //download temp file data
    func downloadModelToLocal(from remoteURL: URL, uniqueKey: String) async throws -> URL {
        var request = URLRequest(url: remoteURL)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw URLError(.badServerResponse)
        }

        let ext = remoteURL.lastPathComponent.components(separatedBy: "?").first
            .flatMap { ($0 as NSString).pathExtension.isEmpty ? nil : ($0 as NSString).pathExtension } ?? "usdz"

        let safeKey = uniqueKey
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        let fileName = "\(safeKey).\(ext)"
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: localURL.path) {
            try FileManager.default.removeItem(at: localURL)
        }

        try data.write(to: localURL)
        return localURL
    }
    
    func loadLocalModelURL(path: String, bucket: String) async -> URL? {
        guard let remoteURL = await getModelURL(path: path, bucket: bucket) else {
            return nil
        }
        return try? await downloadModelToLocal(from: remoteURL, uniqueKey: "\(bucket)_\(path)")
    }
    
    func loadScene() async {
        await performAssetLoading {
            guard let design else { print("No design found"); return }

            var bandURL: URL?
            var bandSource: BandSourceComponent
            var savedBandForSetup: BandComponent? = design.band
            var useBundledFallback = false

            if let savedBand = design.band {
                bandSource = BandSourceComponent(
                    libraryAssetID: savedBand.libraryAssetID,
                    assetStoragePath: savedBand.assetStoragePath,
                    name: savedBand.name
                )

                if savedBand.assetStoragePath == "Flat_Band_Ring" {
                    useBundledFallback = true
                } else {
                    bandURL = await loadLocalModelURL(path: savedBand.assetStoragePath, bucket: "band")
                    if bandURL == nil {
                        print("Saved band asset not found in storage (\(savedBand.assetStoragePath)), falling back to first Supabase band")
                    }
                }
            } else {
                bandSource = BandSourceComponent(libraryAssetID: UUID(), assetStoragePath: "Flat_Band_Ring", name: "plain band usd")
                useBundledFallback = true
            }

            var gemURLs: [String: URL] = [:]
            for gem in design.gems {
                guard let url = await loadLocalModelURL(path: gem.assetStoragePath, bucket: "stone") else {
                    print("Failed to download stone")
                    continue
                }
                gemURLs[gem.name] = url
            }

            if useBundledFallback {
                await scene.setup(bandURL: nil, bandSource: bandSource, gemURLs: gemURLs, mode: mode, savedGems: design.gems, savedBand: savedBandForSetup)
                return
            }

            if bandURL == nil {
                if bands.isEmpty { await fetchBands() }
                guard let firstBand = bands.first else { print("No bands available from Supabase at all"); return }
                currentBand = firstBand
                bandURL = await loadLocalModelURL(path: firstBand.assetId.storagePath, bucket: "band")
                bandSource = BandSourceComponent(
                    libraryAssetID: firstBand.id,
                    assetStoragePath: firstBand.assetId.storagePath,
                    name: firstBand.description
                )
                savedBandForSetup = nil
            }

            guard let finalBandURL = bandURL else { print("Failed to download any band"); return }

            await scene.setup(bandURL: finalBandURL, bandSource: bandSource, gemURLs: gemURLs, mode: mode, savedGems: design.gems, savedBand: savedBandForSetup)
        }
    }
    
    private func applyPlaceholderBand() async {
        await performAssetLoading {
            currentBand = nil
            scene.gizmoController.deselect()
            await scene.loadBundledBand(named: "Flat_Band_Ring", saved: design?.band)
            pendingBandAssetPath = "Flat_Band_Ring"
            pendingBandName = "plain band usd"
            markDirty()
        }
    }
    
    private func applySelectedBand(_ band: Band) async {
        await performAssetLoading {
            guard let localURL = await loadLocalModelURL(path: band.assetId.storagePath, bucket: "band") else {
                print("Failed to download band model \(band.assetId.storagePath)")
                return
            }
            scene.gizmoController.deselect()
            currentBand = band

            let source = BandSourceComponent(
                libraryAssetID: band.id,
                assetStoragePath: band.assetId.storagePath,
                name: band.description
            )
            await scene.replaceBand(from: localURL, source: source, saved: design?.band)
            markDirty()
        }
    }

    private func loadInitialBand() async {
        guard let band = bands.first else {
            print("No bands from Supabase yet, using bundled placeholder")
            await applyPlaceholderBand()
            return
        }
        await applySelectedBand(band)
    }
    
    func loadBand(from band: Band) async {
        await applySelectedBand(band)
    }
    
     func selectBand(style: BandStyle, thickness: String, material: BandMaterialEnum? = nil) async {
        let targetMaterial = material ?? defaultBandMaterial ?? .yellowGold

        guard let match = bands.first(where: {
            $0.bandStyleID.id == style.id &&
            $0.bandThickness.caseInsensitiveCompare(thickness) == .orderedSame &&
            normalizedMaterial($0.bandMaterial) == normalizedMaterial(targetMaterial.rawValue)
        }) else {
            print("No band in Supabase for style '\(style.bandStyleName)' + thickness '\(thickness)' + material '\(targetMaterial.title)'")
            return
        }

        await applySelectedBand(match)
    }
    
    private func normalizedMaterial(_ raw: String) -> String {
        raw.lowercased().replacingOccurrences(of: " ", with: "")
    }
    
    var defaultBandMaterial: BandMaterialEnum? {
        guard let first = bands.first else { return nil }
        return BandMaterialEnum.allCases.first {
            normalizedMaterial(first.bandMaterial) == normalizedMaterial($0.rawValue)
        }
    }

    func band(forStyle style: BandStyle?, thickness: String, material: BandMaterialEnum) -> Band? {
        guard let style else { return nil }
        return bands.first {
            $0.bandStyleID.id == style.id &&
            $0.bandThickness.caseInsensitiveCompare(thickness) == .orderedSame &&
            normalizedMaterial($0.bandMaterial) == normalizedMaterial(material.rawValue)
        }
    }
    

    func thicknessLabel(forSliderValue value: Double) -> String {
        switch Int(value.rounded()) {
        case 1: return "thin"
        case 2: return "medium"
        default: return "thick"
        }
    }
    
    func updateThickness(sliderValue: Double) {
        currentBand?.bandThickness = thicknessLabel(forSliderValue: sliderValue)
    }
    
    func selectBandStyle(named styleName: String) async {
        guard let match = bands.first(where: {
            $0.bandStyleID.bandStyleName.caseInsensitiveCompare(styleName) == .orderedSame
        }) else {
            print("No band in Supabase yet for style '\(styleName)'")
            return
        }
        await loadBand(from: match)
    }
    
    func selectGem(shape: String, material: String) async {
        await performAssetLoading {
            guard let match = gems.first(where: {
                $0.gemShape.caseInsensitiveCompare(shape) == .orderedSame &&
                $0.gemMaterial.caseInsensitiveCompare(material) == .orderedSame
            }) else { return }
            guard let localURL = await loadLocalModelURL(path: match.assetId.storagePath, bucket: "stone") else { return }

            if let entity = await scene.addStone(from: localURL, source: match) {
                selectGem(entity)
                markDirty()
            }
        }
    }
    
    private func performAssetLoading<T>(_ operation: () async -> T) async -> T {
        isLoadingAsset = true
        defer { isLoadingAsset = false }
        return await operation()
    }

    func loadGem(from gem: Gem, screenLocation: CGPoint? = nil, containerSize: CGSize? = nil) async {
        await performAssetLoading {
            guard let localURL = await loadLocalModelURL(path: gem.assetId.storagePath, bucket: "stone") else {
                return
            }

            if let entity = await scene.addStone(from: localURL, source: gem, screenLocation: screenLocation, containerSize: containerSize) {
                selectGem(entity)
                markDirty()
            }
        }
    }
    
    func thumbnailURL(for asset: Asset3D) -> URL? {
        do {
            return try supabase.storage
                .from("thumbnail")
                .getPublicURL(path: asset.thumbnailPath)
        } catch {
            print("Thumbnail URL error:", error)
            return nil
        }
    }
    
    var uniqueBandsByStyle: [Band] {

        var seen = Set<UUID>()

        return bands.filter { band in

            let styleId = band.bandStyleID.id

            if seen.contains(styleId) {
                return false
            }

            seen.insert(styleId)

            return true
        }
    }
    
    func selectAndAlign(_ gem: Entity) {
        selectedGemName = gem.name

        let allSnapPoints = scene.allSnapPoints()
        
        if let target = SnappingService.nearestSnapPoint(
            to: gem,
            among: allSnapPoints,
            maxDistance: tapAlignRadius,
            allowOccupiedBySelf: gem.name
        ) {
            SnappingService.attach(gem: gem, to: target)
            markDirty()
        }
    }

    func prepareGemForDragging(_ gem: Entity) {
        selectedGemName = gem.name

        if SnappingService.isAttached(gem) {
            SnappingService.detach(gem: gem, backTo: scene.gemAnchor)
        }

        var state = gem.gestureStateComponent
        state.lastPositionDrag = gem.position(relativeTo: nil)
        gem.gestureStateComponent = state

        markDirty()
    }

    func sceneTransformTarget() -> Entity {
        if let selectedGemName,
           let gem = scene.allGemEntities().first(where: { $0.name == selectedGemName }) {
            return gem
        }

        switch mode {
        case .band:
            return scene.bandPivot
        case .handMannequin:
            return scene.mannequinPivot
        }
    }

    func reapplyAttachedGemScales() {
        for snap in scene.allSnapPoints() {
            for child in snap.children {
                SnappingService.reapplyFixedScale(for: child)
            }
        }
    }

    func delete() {
        guard let name = selectedGemName, let gem = scene.allGemEntities().first(where: { $0.name == name }) else {
            return
        }

        if gem.components[AttachmentComponent.self]?.attachedSnapID != nil {
            SnappingService.detach(gem: gem, backTo: scene.gemAnchor)
        }
        
        scene.gizmoController.deselect()
        clearGemDragButtons()
        scene.setSnapPointVisualsVisible(false)
        gem.removeFromParent()

        if let design = designFile.design, let modelContext {
            persistence.delete(gemName: name, from: design, modelContext: modelContext)
        }

        selectedGemName = nil
        hasUnsavedChanges = true
    }

    func save(ringSizeID: Int?, ringSizeSystem: RingSizeSystem?, finger: Finger, hand: Hand) {
        guard let modelContext, let design = designFile.design else { return }
        do {
            try persistence.save(
                gemEntities: scene.allGemEntities(),
                bandEntity: scene.bandAnchor.children.first,
                bandPivot: scene.bandPivot,
                ringSizeID: ringSizeID,
                ringSizeSystem: ringSizeSystem,
                finger: finger,
                hand: hand,
                designFile: designFile,
                design: design,
                modelContext: modelContext
            )
            scene.gizmoController.updateGizmoTransform()
            hasUnsavedChanges = false
        } catch {
            print("save failed: \(error)")
        }
    }
    
    private func replaceBand() async {
        await loadInitialBand()
    }
    
    func handleDrop(item: JewelryDropPayload, screenLocation: CGPoint? = nil, containerSize: CGSize? = nil) async {
        isLoadingAsset = true
        await Task.yield()
        defer {
            isLoadingAsset = false
        }

        switch item.type {
        case "band":
            guard let band = bands.first(where: { $0.id == item.id}) else {
                return
            }
            await loadBand(from: band)

        case "gem":
            guard let gem = gems.first(where: { $0.id == item.id }) else {
                return
            }
            await loadGem(from: gem, screenLocation: screenLocation, containerSize: containerSize)

        default:
            print("Unknown drop type:", item.type)
        }
    }
    
    func syncSelectionFromGizmo() {
        guard let entity = scene.gizmoController.selectedEntity,
              entity.components[GestureComponent.self]?.typeJewelry == .gemstone else {

            selectedGemName = nil
            isGemSelected = false
            selectedGemTrashPosition = nil
            selectedGemRotatePosition = nil
            selectedGemScalePosition = nil
            selectedGemButtonAnchor = nil
            return
        }

        selectedGemName = entity.name
        isGemSelected = true

        if let anchors = scene.screenAnchorPoints(for: entity) {
            selectedGemButtonAnchor = anchors.center
        }
    }

    func updateSelectedGemIconPositions() {
        guard isGemSelected, let anchor = selectedGemButtonAnchor else {
            selectedGemTrashPosition = nil
            selectedGemRotatePosition = nil
            selectedGemScalePosition = nil
            return
        }

        let spacing: CGFloat = 70

        selectedGemTrashPosition = CGPoint(x: anchor.x - spacing, y: anchor.y)
        selectedGemScalePosition = anchor
        selectedGemRotatePosition = CGPoint(x: anchor.x + spacing, y: anchor.y)
    }
    
    func updateSelectedGemButtonPosition(for entity: Entity) {
        guard isGemSelected, selectedGemName == entity.name else {
            return
        }

        guard let anchors = scene.screenAnchorPoints(for: entity) else {
            return
        }

        selectedGemButtonAnchor = anchors.center
        updateSelectedGemIconPositions()
    }

    func requestDeleteSelectedGem() {
        guard let entity = scene.gizmoController.selectedEntity else {
            return
        }
        requestDelete(for: entity)
    }
    
    //scale button
    func beginScaleSelectedGem() {
        guard let entity = scene.gizmoController.selectedEntity,
              entity.components[GestureComponent.self]?.typeJewelry == .gemstone else {
            return
        }
        scaleDragStartLocalScale = entity.scale
    }
    
    func updateScaleSelectedGem(translationHeight: CGFloat) {
        guard let entity = scene.gizmoController.selectedEntity,
              entity.components[GestureComponent.self]?.typeJewelry == .gemstone,
              let startScale = scaleDragStartLocalScale else {
            return
        }

        let rawFactor = 1 - Float(translationHeight) * scaleDragSensitivity
        let clampedFactor = max(scaleFactorMin, min(rawFactor, scaleFactorMax))

        entity.scale = startScale * clampedFactor
        scene.gizmoController.updateGizmoTransform()
    }

    func endScaleSelectedGem() {
        defer { scaleDragStartLocalScale = nil }

        guard let entity = scene.gizmoController.selectedEntity,
              entity.components[GestureComponent.self]?.typeJewelry == .gemstone else {
            return
        }

        if var attachment = entity.components[AttachmentComponent.self] {
            let worldScale = entity.scale(relativeTo: nil)
            attachment.targetWorldScale = (worldScale.x + worldScale.y + worldScale.z) / 3
            entity.components[AttachmentComponent.self] = attachment
        }

        markDirty()
    }
    
    //rotate button
    func beginRotateSelectedGem() {
        guard let entity = scene.gizmoController.selectedEntity,
              entity.components[GestureComponent.self]?.typeJewelry == .gemstone else {
            return
        }
    }

    func updateRotateSelectedGem(deltaAngleRadians: Float) {
        guard let entity = scene.gizmoController.selectedEntity,
              entity.components[GestureComponent.self]?.typeJewelry == .gemstone else {
            return
        }

        let deltaDegrees = deltaAngleRadians * 180 / .pi
        scene.rotateSelectedGemAroundViewAxis(byDegrees: deltaDegrees)
        markDirty()
    }

    func endRotateSelectedGem() {
        //end rotate
    }
    
    //end drag, three button gone
    func clearGemDragButtons() {
        isGemSelected = false
        selectedGemName = nil
        selectedGemButtonAnchor = nil
        selectedGemTrashPosition = nil
        selectedGemRotatePosition = nil
        selectedGemScalePosition = nil
    }
}


