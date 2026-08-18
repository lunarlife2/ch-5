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
    var errorMessage: String?

    
    private(set) var currentBand: Band?

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
    
    func fetchBands() async {
        do {
            let bands: [Band] = try await supabase
                .from("ms_band")
                .select("""
                    band_id,
                    description,
                    band_thickness,
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

    func loadScene() async {
        guard let design else {
            print("No design found")
            return
        }

        var bandURL: URL?
        var savedBandForSetup: BandComponent? = design.band

        if let savedBand = design.band {
            bandURL = await loadLocalModelURL(path: savedBand.assetStoragePath, bucket: "band")
            if bandURL == nil {
                print("Saved band asset not found in storage (\(savedBand.assetStoragePath)), falling back to first Supabase band")
            }
        } else {
            print("No saved band, falling back to first Supabase band")
        }

        if bandURL == nil {
            if bands.isEmpty {
                await fetchBands()
            }
            guard let firstBand = bands.first else {
                print("No bands available from Supabase at all")
                return
            }
            currentBand = firstBand
            bandURL = await loadLocalModelURL(path: firstBand.assetId.storagePath, bucket: "band")
            savedBandForSetup = nil // belum ada saved band component yang valid untuk posisi/orientasi
        }

        guard let finalBandURL = bandURL else {
            print("Failed to download any band")
            return
        }

        var gemURLs: [String: URL] = [:]
        for gem in design.gems {
            guard let url = await loadLocalModelURL(path: gem.assetStoragePath, bucket: "stone") else {
                print("Failed to download stone")
                continue
            }
            gemURLs[gem.name] = url
        }

        await scene.setup(bandURL: finalBandURL, gemURLs: gemURLs, mode: mode, savedGems: design.gems, savedBand: savedBandForSetup)
    }
    
    private func loadInitialBand() async {
        guard let band = bands.first else {
            print("No bands from Supabase yet, using bundled placeholder")
            await loadBand(named: "Flat_Band_Ring")
            return
        }
        await loadBand(from: band)
    }
    
    func loadBand(from band: Band) async {
        currentBand = band
        //check the actual bucket name on Supabase Storage
        guard let localURL = await loadLocalModelURL(path: band.assetId.storagePath, bucket: "band") else {
            print("Failed to download band model \(band.assetId.storagePath), using bundled placeholder")
            await loadBand(named: "Flat_Band_Ring")
            return
        }
        
        do {
            let entity = try await ModelEntity(contentsOf: localURL)
            place(bandEntity: entity)
        } catch {
            print("Failed to load downloaded band entity", error)
            await loadBand(named: "Flat_Band_Ring")
        }
    }
    
    private func loadBand(named name: String) async {
        do {
            let plainBand = try await Entity(named: name)
            place(bandEntity: plainBand)
        }
        catch {
            print("Failed to load band entity", error)
        }
    }
    
    
    private func place(bandEntity: Entity) {
        let bandSize = bandEntity.visualBounds(relativeTo: nil).extents
        let targetBandDiameter: Float = 0.004
        bandEntity.scale = .init(repeating: targetBandDiameter / max(bandSize.x, bandSize.y))
        bandEntity.position = [-0.001, 0, 0]
        
        bandEntity.generateCollisionShapes(recursive: true)
        bandEntity.components.set(InputTargetComponent())
        bandEntity.components.set(GestureComponent(typeJewelry: .band, canDrag: false, canScale: true, canRotate: true))
        
        scene.bandAnchor.children.removeAll()
        scene.bandAnchor.addChild(bandEntity)
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
    
    func selectBand(style: BandStyle, thickness: String) async {
        guard let match = bands.first(where: {
            $0.bandStyleID.id == style.id &&
            $0.bandThickness.caseInsensitiveCompare(thickness) == .orderedSame
        }) else {
            print("No band in Supabase for style '\(style.bandStyleName)' + thickness '\(thickness)'")
            return
        }
        
        currentBand = match
        
        guard let localURL = await loadLocalModelURL(path: match.assetId.storagePath, bucket: "band") else {
            print("Failed to download band")
            return
        }
        
        await scene.replaceBand(from: localURL, saved: design?.band)
        
        markDirty()
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
        guard let match = gems.first(where: {
            $0.gemShape.caseInsensitiveCompare(shape) == .orderedSame &&
            $0.gemMaterial.caseInsensitiveCompare(material) == .orderedSame
        }) else {
            print("No gem in Supabase for shape '\(shape)' + material '\(material)'")
            return
        }
        guard let localURL = await loadLocalModelURL(path: match.assetId.storagePath, bucket: "stone") else {
            print("Failed to download gem")
            return
        }
        
        if let entity = await scene.addStone(from: localURL) {
            selectGem(entity)
            markDirty()
        }
    }
    
    
    func loadGem(from gem: Gem, screenLocation: CGPoint? = nil, containerSize: CGSize? = nil) async {
        guard let localURL = await loadLocalModelURL(path: gem.assetId.storagePath, bucket: "stone") else {
            print("Failed to download gem model \(gem.assetId.storagePath)")
            return
        }
        
        if let entity = await scene.addStone(from: localURL, screenLocation: screenLocation, containerSize: containerSize) {
            selectGem(entity)
            markDirty()
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
        guard let name = selectedGemName,
              let gem = scene.allGemEntities().first(where: { $0.name == name })
        else { return }

        if gem.components[AttachmentComponent.self]?.attachedSnapID != nil {
            SnappingService.detach(gem: gem, backTo: scene.gemAnchor)
        }
        gem.removeFromParent()

        if let design = designFile.design, let modelContext {
            persistence.delete(gemName: name, from: design, modelContext: modelContext)
        }

        selectedGemName = nil
        hasUnsavedChanges = true
    }

    func save(ringSizeID: Int?, ringSizeSystem: RingSizeSystem?) {
        guard let modelContext, let design = designFile.design else { return }
        do {
            try persistence.save(
                gemEntities: scene.allGemEntities(),
                bandEntity: scene.bandAnchor.children.first,
                bandPivot: scene.bandPivot,
                pendingBandAssetPath: pendingBandAssetPath,
                pendingBandName: pendingBandName,
                ringSizeID: ringSizeID,
                ringSizeSystem: ringSizeSystem,
                designFile: designFile,
                design: design,
                modelContext: modelContext
            )
            hasUnsavedChanges = false
        } catch {
            print("save failed: \(error)")
        }
    }
    
    private func replaceBand() async {
        await loadInitialBand()
    }
    
    func handleDrop(item: JewelryDropPayload, screenLocation: CGPoint? = nil, containerSize: CGSize? = nil) async {
        switch item.type {
        case "band":
            guard let band = bands.first(where: { $0.id == item.id }) else {
                return
            }
            await loadBand(from: band)
            
        case "gem":
            guard let gem = gems.first(where: { $0.id == item.id }) else {
                return
            }
            await loadGem(from: gem, screenLocation: screenLocation, containerSize: containerSize)
            
        default:
            print("Unknown drop type: ", item.type)
        }
    }
}


