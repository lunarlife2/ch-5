//
//  EditViewModel.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//
import Foundation
import SwiftUI
import RealityKit
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
    
    
    private(set) var _mode: JewelryEditorMode = .band
    
    var mode: JewelryEditorMode {
        get {
            _mode
        }
        set {
            _mode = newValue
            updateVisibility()
        }
    }
    
    let rootEntity = Entity()
    
    let bandPivot = Entity()
    let bandAnchor = Entity()
    
    let gemAnchor = Entity()
    
    let mannequinAnchor = Entity()
    let mannequinPivot = Entity()
    
    let camera = Entity()
    
    var band: Entity {
        bandAnchor
    }
    var selectedGem: Entity {
        gemAnchor
    }
    var mannequin: Entity {
        mannequinAnchor
    }
    var rotationY: Float = 0
    var rotationX: Float = 0
    var isDraggingGem = false
    var scale: Float = 1
    
    private var isSetup = false
    
    private var realityContent: RealityViewCameraContent?
    
    func setRealityContent(_ content: RealityViewCameraContent) {
        realityContent = content
    }
    
    func entityAtScreenLocation(_ location: CGPoint) -> Entity? {
        guard let realityContent else {
            return nil
        }

        let hitEntity = realityContent.entity( at: location, in: .local)

        guard let hitEntity else {
            return nil
        }

        return hitEntity.gestureTarget()
    }
    
    
    func save() {
        //save edit
    }
    
    func delete(){
        //delete edit
    }
    
    private func updateVisibility() {
        bandPivot.isEnabled = mode == .band
        mannequinPivot.isEnabled = mode == .handMannequin
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
        
        bandAnchor.children.removeAll()
        bandAnchor.addChild(bandEntity)
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
        await loadBand(from: match)
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
        await loadGem(from: match)
    }
    
    
    func loadGem(from gem: Gem) async {
        guard let localURL = await loadLocalModelURL(path: gem.assetId.storagePath, bucket: "stone") else {
            print("Failed to download gem model \(gem.assetId.storagePath)")
            return
        }
        
        do {
            let entity = try await ModelEntity(contentsOf: localURL)
            let size = entity.visualBounds(relativeTo: nil).extents
            let targetDiameter: Float = 0.004
            entity.scale = .init(repeating: targetDiameter / max(size.x, size.y))
            entity.name = "SelectedGem"
            entity.position = [0, 1, 0]
            
            entity.generateCollisionShapes(recursive: true)
            entity.components.set(InputTargetComponent())
            entity.components.set(GestureComponent(typeJewelry: .gemstone, canDrag: true, canScale: true, canRotate: true))
            
//            gemAnchor.children.removeAll { $0.name == "SelectedGem" }
            gemAnchor.addChild(entity)
        } catch {
            print("Failed to load downloaded gem entity", error)
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
    
//    private func loadBand() async {
//        do {
//            //load
//            let plainBand = try await Entity(named: "Flat_Band_Ring")
//            //size
//            let plainBandSize = plainBand.visualBounds(relativeTo: nil).extents
//            let targetBandDiameter: Float = 0.004
//            //scale
//            plainBand.scale = .init(repeating:targetBandDiameter / max(plainBandSize.x,plainBandSize.y))
//            plainBand.position = [-0.001, 0, 0]
//            //band input
//            plainBand.generateCollisionShapes(recursive: true)
//            plainBand.components.set(InputTargetComponent())
//            plainBand.components.set(GestureComponent(typeJewelry: .band, canDrag: false, canScale: true, canRotate: true))
//            
//            //hierarchy
//            bandAnchor.addChild(plainBand)
//        }
//        catch {
//            print("Failed to load band entity", error)
//        }
//    }
    
    private func loadMannequin() async {
        do {
            //load
            let mannequin = try await Entity(named: "Simplified_Hand_For_Artists")
            //size
            let mannequinSize = mannequin.visualBounds(relativeTo: nil).extents
            let targetMannequinDiameter: Float = 0.008
            //scale
            mannequin.scale = .init(repeating:targetMannequinDiameter / max(mannequinSize.x,mannequinSize.y))
            mannequin.position = [0, -0.5, 0]
            //mannequin input
            mannequin.generateCollisionShapes(recursive: true, static: true)
            mannequin.components.set(InputTargetComponent())
            mannequin.components.set(GestureComponent(typeJewelry: .handMannequin, canDrag: false, canScale: true, canRotate: true))
            
            //hierarchy
            mannequinAnchor.addChild(mannequin)
        }
        catch {
            print("Failed to load entity", error)
        }
    }
    
    
//    public func addStone(screenLocation: CGPoint? = nil, containerSize: CGSize? = nil) async {
//        print("Stone Added")
//        
//        do {
//            let gemstone = try await Entity(named: "Gemstone")
//            
//            let gemstoneSize = gemstone.visualBounds(relativeTo: nil).extents
//            let targetGemstoneDiameter: Float = 0.004
//            //scale
//            gemstone.scale = .init(repeating:targetGemstoneDiameter / max(gemstoneSize.x,gemstoneSize.y))
//            
//            gemstone.name = "Gemstone"
//            
//            if let loc = screenLocation, let size = containerSize {
//                let nx = Float(loc.x / size.width) - 0.5
//                let nz = Float(loc.y / size.height) - 0.5
//                gemstone.position = [nx * 0.02, 1, nz * 0.02]
//            } else {
//                gemstone.position = [0, 1, 0]
//            }
//            
//            gemstone.generateCollisionShapes(recursive: true)
//            gemstone.components.set(InputTargetComponent())
//            gemstone.components.set(GestureComponent(typeJewelry: .gemstone, canDrag: true, canScale: true, canRotate: true))
//            
//            gemAnchor.addChild(gemstone)
//            
//            print("Gem parent:", gemstone.parent?.name ?? "nil")
//            print("Gem position:", gemstone.position)
//            print("Gem anchor children:", gemAnchor.children.count)
//        }
//        catch {
//            print("Failed to load entity", error)
//        }
//    }
//
    
    public func addStone(screenLocation: CGPoint? = nil, containerSize: CGSize? = nil) async {
        print("Stone Added")
        do {
            let gemstone = try await Entity(named: "Gemstone")
            
            let gemstoneSize = gemstone.visualBounds(relativeTo: nil).extents
            let targetGemstoneDiameter: Float = 0.004
            //scale
            gemstone.scale = .init(repeating:targetGemstoneDiameter / max(gemstoneSize.x,gemstoneSize.y))
            gemstone.name = "Gemstone"
            
            if let loc = screenLocation, let size = containerSize {
                let nx = Float(loc.x / size.width) - 0.5
                let nz = Float(loc.y / size.height) - 0.5
                gemstone.position = [nx * 0.02, 1, nz * 0.02]
            } else {
                gemstone.position = [0, 1, 0]
            }
            
            gemstone.generateCollisionShapes(recursive: true)
            gemstone.components.set(InputTargetComponent())
            gemstone.components.set(GestureComponent(typeJewelry: .gemstone, canDrag: true, canScale: true, canRotate: true))
            
            gemAnchor.addChild(gemstone)
            
            print("Gem parent:", gemstone.parent?.name ?? "nil")
            print("Gem position:", gemstone.position)
            print("Gem anchor children:", gemAnchor.children.count)
        }
        catch {
            print("Failed to load entity", error)
        }
    }
    
    func handleDrop(identifier: String, screenLocation: CGPoint? = nil, containerSize: CGSize? = nil) async {
        switch identifier {
        case "Flat_Band_Ring":
            await replaceBand()
        case "Gemstone":
            await addStone(screenLocation: screenLocation, containerSize: containerSize)
        default:
            print("Unknown drop identifier:", identifier)
        }
    }
    
    func setup() async {
        guard !isSetup else {
            return
        }
        isSetup = true
        
        await fetchAllData()
        await loadInitialBand()
        await loadMannequin()
        
        //band
        bandPivot.addChild(bandAnchor)
        rootEntity.addChild(bandPivot)
        
        //mannequin
        mannequinPivot.addChild(mannequinAnchor)
        rootEntity.addChild(mannequinPivot)
        
        //gem
        rootEntity.addChild(gemAnchor)
        
        updateVisibility()
    }
    
    
    private func replaceBand() async {
        await loadInitialBand()
    }
    
}
