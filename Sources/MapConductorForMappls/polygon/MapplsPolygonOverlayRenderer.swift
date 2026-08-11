import MapConductorCore
import MapplsMap

@MainActor
final class MapplsPolygonOverlayRenderer: AbstractPolygonOverlayRenderer<[MGLPolygonFeature]> {
    private weak var mapView: MGLMapView?
    private var style: MGLStyle?

    let polygonLayer: PolygonLayer
    private let polygonManager: PolygonManager<[MGLPolygonFeature]>

    init(
        mapView: MGLMapView?,
        polygonManager: PolygonManager<[MGLPolygonFeature]>,
        polygonLayer: PolygonLayer
    ) {
        self.mapView = mapView
        self.polygonManager = polygonManager
        self.polygonLayer = polygonLayer
        super.init()
    }

    func onStyleLoaded(_ style: MGLStyle) {
        self.style = style
        polygonLayer.ensureAdded(to: style)
    }

    func unbind() {
        if let style {
            polygonLayer.remove(from: style)
        }
        style = nil
        mapView = nil
    }

    /// 複数の穴が重なっている場合は結合（union）して重複を解消する。
    /// 他プロバイダ（MapLibre/TomTom 等）と同じ `unionHoles()` を用いる。
    ///
    /// Mappls（MapLibre GL）は Polygon の inner ring で複数の穴を描けるが、偶奇規則なので
    /// 重なった穴は打ち消し合い、重なり部分が塗られてしまう。コンポーネント層（`Polygon`）の
    /// ユニオンは state 1 インスタンスにつき 1 回きりで、頂点ドラッグ後の `state.holes`
    /// 差し替えには追従しないため、android-for-mappls と同じくここでも結合する。
    private func resolveHoles(_ state: PolygonState) -> PolygonState {
        state.holes.count > 1 ? state.unionHoles() : state
    }

    override func createPolygon(state: PolygonState) async -> [MGLPolygonFeature]? {
        let resolved = resolveHoles(state)
        let features = createMapplsPolygons(
            id: resolved.id,
            points: resolved.points,
            geodesic: resolved.geodesic,
            fillColor: resolved.fillColor,
            strokeColor: resolved.strokeColor,
            strokeWidth: resolved.strokeWidth,
            zIndex: resolved.zIndex,
            holes: resolved.holes
        )
        return features.isEmpty ? nil : features
    }

    override func updatePolygonProperties(
        polygon: [MGLPolygonFeature],
        current: PolygonEntity<[MGLPolygonFeature]>,
        prev: PolygonEntity<[MGLPolygonFeature]>
    ) async -> [MGLPolygonFeature]? {
        return await createPolygon(state: current.state)
    }

    override func removePolygon(entity: PolygonEntity<[MGLPolygonFeature]>) async {
        // Removal is handled by redrawing all remaining polygons in onPostProcess.
    }

    override func onPostProcess() async {
        let features = polygonManager.allEntities().flatMap { $0.polygon ?? [] }
        polygonLayer.setFeatures(features)
    }
}
