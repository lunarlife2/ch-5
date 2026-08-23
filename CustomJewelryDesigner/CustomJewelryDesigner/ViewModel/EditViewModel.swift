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
    init(designFile: DesignFile) {
        self.designFile = designFile
    }
    
    let scene = JewelrySceneController()
    
    private let persistence = DesignPersistenceService()
    private(set) var designFile: DesignFile
    private var modelContext: ModelContext?

    var mode: JewelryEditorMode = .band {
        didSet {
            scene.updateVisibility(for: mode)
            scene.updateGizmoTarget(for: mode)
        }
    }
    
    //attach band gem to mannequin
    var selectedHandFinger: HandFinger = .rightthumb {
        didSet { scene.attachBandToFinger(selectedHandFinger) }
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
    var liveDragGlobalPoint: CGPoint?
    
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
    
    //selected band
    private(set) var selectedBandStyle: BandStyle?
    private(set) var selectedBandThickness: String?
    private(set) var selectedBandMaterial: BandMaterialEnum?
    
    //attach band gem to mannequin
//    func restoreLastFingerSelection() {
//        if let saved = design?.handFinger, saved.isAvailable {
//            selectedHandFinger = saved
//        }
//    }

    
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
    private(set) var editorFrameInGlobal: CGRect = .zero
    private(set) var trashFrameInGlobal: CGRect = .zero
    private(set) var bottomControlsFrameInGlobal: CGRect = .zero
    
    private var pendingBandAssetPath: String = "Flat_Band_Ring"
    private var pendingBandName: String = "plain band usd"
    
    private let snapScreenRadius: CGFloat = 50
    private let tapAlignRadius: Float = 0.0025
    
    private let uiClampMargin: CGFloat = 12
    
    //skincolor
    var skinColor: Color {
        Color(scene.skinColor)
    }

    func setSkinColor(_ color: Color) {
        scene.applySkinColor(UIColor(color))
        markDirty()
    }

    var design: Design? {
        designFile.design
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
    
    func setBottomControlsFrame(_ frame: CGRect) {
        bottomControlsFrameInGlobal = frame
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

            for gem in gems {
                print(
                    "Shape:", gem.gemShape,
                    "| Material:", gem.gemMaterial,
                    "| Storage:", gem.assetId.storagePath
                )
            }
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
    
    func fetchMannequinAsset(for hand: Hand) async -> Asset3D? {
        let path = hand == .left
            ? "realHand.usdz"
            : "rightHand.usdz"

        do {
            let assets: [Asset3D] = try await supabase
                .from("ms_3d_asset")
                .select("""
                    asset_id,
                    storage_path,
                    thumbnail_path
                """)
                .eq("storage_path", value: path)
                .limit(1)
                .execute()
                .value

            guard let asset = assets.first else {
                print("❌ \(path) tidak ditemukan di ms_3d_asset")
                return nil
            }

            print("✅ \(hand) mannequin found:")
            print("   ID:", asset.id)
            print("   Storage:", asset.storagePath)

            return asset

        } catch {
            print("❌ Failed to fetch \(hand) mannequin asset:", error)
            return nil
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

            let leftMannequinURL: URL?

            if let leftAsset = await fetchMannequinAsset(for: .left) {
                leftMannequinURL = await loadLocalModelURL(
                    path: leftAsset.storagePath,
                    bucket: "hand"
                )
            } else {
                leftMannequinURL = nil
            }

            let rightMannequinURL: URL?

            if let rightAsset = await fetchMannequinAsset(for: .right) {
                rightMannequinURL = await loadLocalModelURL(
                    path: rightAsset.storagePath,
                    bucket: "hand"
                )
            } else {
                rightMannequinURL = nil
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
                await scene.setup(bandURL: nil, bandSource: bandSource, leftMannequinURL: leftMannequinURL, rightMannequinURL: rightMannequinURL, gemURLs: gemURLs, mode: mode, savedGems: design.gems, savedBand: savedBandForSetup)
                return
            }
            
            if let hex = design.skinColorHex {
                scene.applySkinColor(UIColor(Color(hex: hex)))
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

            await scene.setup(bandURL: finalBandURL, bandSource: bandSource, leftMannequinURL: leftMannequinURL, rightMannequinURL: rightMannequinURL, gemURLs: gemURLs, mode: mode, savedGems: design.gems, savedBand: savedBandForSetup)
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
        
        selectedBandStyle = match.bandStyleID
        selectedBandThickness = match.bandThickness
        
        selectedBandMaterial = BandMaterialEnum.allCases.first { normalizedMaterial($0.rawValue) == normalizedMaterial(match.bandMaterial) }
        await applySelectedBand(match)
    }
    
    private func normalizedMaterial(_ raw: String) -> String {
        raw.lowercased().filter { $0.isLetter || $0.isNumber }
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
            }) else {
                print("❌ No gem match for \(shape)/\(material)")
                return
            }
            print("✅ Match found: \(match.assetId.storagePath)")

            guard let localURL = await loadLocalModelURL(path: match.assetId.storagePath, bucket: "stone") else {
                print("❌ Failed to download/get URL for \(match.assetId.storagePath)")
                return
            }
            print("✅ Downloaded to: \(localURL)")

            if let entity = await scene.addStone(from: localURL, source: match) {
                print("✅ Entity added to scene: \(entity.name), position: \(entity.position), scale: \(entity.scale)")
                selectGem(entity)
                markDirty()
            } else {
                print("❌ scene.addStone returned nil for \(match.assetId.storagePath)")
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
    
    var uniqueGemsByShape: [Gem] {
        var seen = Set<String>()
        return gems.filter { gem in
            let key = gem.gemShape.lowercased()
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    func gem(forShape shape: String) -> Gem? {
        gems.first { $0.gemShape.caseInsensitiveCompare(shape) == .orderedSame }
    }

    func gem(forShape shape: String?, material: String) -> Gem? {
        guard let shape else { return nil }
        return gems.first { gem in
            gem.gemShape.caseInsensitiveCompare(shape) == .orderedSame &&
            gem.gemMaterial.caseInsensitiveCompare(material) == .orderedSame
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

    func save(ringSizeID: Int?, ringSizeSystem: RingSizeSystem?, handFinger: HandFinger) {
        guard let modelContext, let design = designFile.design else { return }
        do {
            try persistence.save(
                gemEntities: scene.allGemEntities(),
                bandEntity: scene.bandAnchor.children.first,
                bandAnchor: scene.bandAnchor,
                ringSizeID: ringSizeID,
                ringSizeSystem: ringSizeSystem,
                handFinger: handFinger,
                skinColorHex: skinColor.hexString,
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
        guard
            isGemSelected,
            let selectedGemName,
            let entity = scene.allGemEntities().first(where: {
                $0.name == selectedGemName
            }),
            let anchors = scene.screenAnchorPoints(for: entity)
        else {
            selectedGemTrashPosition = nil
            selectedGemRotatePosition = nil
            selectedGemScalePosition = nil
            return
        }

        let anchor = anchors.center

        selectedGemButtonAnchor = anchor

        let horizontalSpacing: CGFloat = 70
        let verticalOffset: CGFloat = 80

        let buttonY = anchor.y - verticalOffset

        selectedGemTrashPosition = CGPoint(
            x: anchor.x - horizontalSpacing,
            y: buttonY
        )

        selectedGemScalePosition = CGPoint(
            x: anchor.x,
            y: buttonY
        )

        selectedGemRotatePosition = CGPoint(
            x: anchor.x + horizontalSpacing,
            y: buttonY
        )
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
        
        if SnappingService.isAttached(entity) {
            SnappingService.reapplyFixedScale(for: entity)
        }
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
            
            if SnappingService.isAttached(entity) {
                        SnappingService.reapplyFixedScale(for: entity)
                    }
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
        scene.rotateSelectedGemAroundViewXAxis(byDegrees: deltaDegrees)
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
    
    func clampToSafeArea(_ point: CGPoint) -> CGPoint {
        var clamped = point

        if editorFrameInGlobal != .zero {
            clamped.x = min(max(clamped.x, editorFrameInGlobal.minX), editorFrameInGlobal.maxX)
            clamped.y = min(max(clamped.y, editorFrameInGlobal.minY), editorFrameInGlobal.maxY)
        }

        if bottomControlsFrameInGlobal != .zero {
            let blocked = bottomControlsFrameInGlobal.insetBy(dx: -uiClampMargin, dy: -uiClampMargin)
            if blocked.contains(clamped) {
                clamped.y = bottomControlsFrameInGlobal.minY - uiClampMargin
            }
        }

        if editorFrameInGlobal != .zero {
            clamped.x = min(max(clamped.x, editorFrameInGlobal.minX), editorFrameInGlobal.maxX)
            clamped.y = min(max(clamped.y, editorFrameInGlobal.minY), editorFrameInGlobal.maxY)
        }

        return clamped
    }
}
