import MapConductorCore
import MapplsMap
import UIKit

@MainActor
final class MapplsPolylineOverlayRenderer: AbstractPolylineOverlayRenderer<[MGLPolylineFeature]> {
    private weak var mapView: MGLMapView?
    private var style: MGLStyle?

    let polylineLayer: PolylineLayer
    private let polylineManager: PolylineManager<[MGLPolylineFeature]>

    init(
        mapView: MGLMapView?,
        polylineManager: PolylineManager<[MGLPolylineFeature]>,
        polylineLayer: PolylineLayer
    ) {
        self.mapView = mapView
        self.polylineManager = polylineManager
        self.polylineLayer = polylineLayer
        super.init()
    }

    func onStyleLoaded(_ style: MGLStyle) {
        self.style = style
        polylineLayer.ensureAdded(to: style)
    }

    func unbind() {
        if let style {
            polylineLayer.remove(from: style)
        }
        style = nil
        mapView = nil
    }

    override func createPolyline(state: PolylineState) async -> [MGLPolylineFeature]? {
        createMapplsLines(
            id: state.id,
            points: state.points,
            geodesic: state.geodesic,
            strokeColor: state.strokeColor,
            strokeWidth: state.strokeWidth,
            zIndex: state.zIndex
        )
    }

    override func updatePolylineProperties(
        polyline: [MGLPolylineFeature],
        current: PolylineEntity<[MGLPolylineFeature]>,
        prev: PolylineEntity<[MGLPolylineFeature]>
    ) async -> [MGLPolylineFeature]? {
        createMapplsLines(
            id: current.state.id,
            points: current.state.points,
            geodesic: current.state.geodesic,
            strokeColor: current.state.strokeColor,
            strokeWidth: current.state.strokeWidth,
            zIndex: current.state.zIndex
        )
    }

    override func removePolyline(entity: PolylineEntity<[MGLPolylineFeature]>) async {
        // Removal is handled by redrawing all remaining polylines in onPostProcess.
    }

    override func onPostProcess() async {
        guard !polylineManager.isDestroyed else { return }
        let features = polylineManager.allEntities().flatMap { $0.polyline ?? [] }
        polylineLayer.setFeatures(features)
    }
}
