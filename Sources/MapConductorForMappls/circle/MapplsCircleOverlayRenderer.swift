import MapConductorCore
import MapplsMap
import UIKit

@MainActor
final class MapplsCircleOverlayRenderer: AbstractCircleOverlayRenderer<MGLPolygonFeature> {
    private weak var mapView: MGLMapView?
    private var style: MGLStyle?

    let circleLayer: CircleLayer
    private let circleManager: CircleManager<MGLPolygonFeature>

    init(
        mapView: MGLMapView?,
        circleManager: CircleManager<MGLPolygonFeature>,
        circleLayer: CircleLayer
    ) {
        self.mapView = mapView
        self.circleManager = circleManager
        self.circleLayer = circleLayer
        super.init()
    }

    func onStyleLoaded(_ style: MGLStyle) {
        self.style = style
        circleLayer.ensureAdded(to: style)
    }

    func unbind() {
        if let style {
            circleLayer.remove(from: style)
        }
        style = nil
        mapView = nil
    }

    override func createCircle(state: CircleState) async -> MGLPolygonFeature? {
        makeFeature(for: state)
    }

    override func updateCircleProperties(
        circle: MGLPolygonFeature,
        current: CircleEntity<MGLPolygonFeature>,
        prev: CircleEntity<MGLPolygonFeature>
    ) async -> MGLPolygonFeature? {
        makeFeature(for: current.state)
    }

    override func removeCircle(entity: CircleEntity<MGLPolygonFeature>) async {
        // Removal is handled by redrawing all remaining circles in onPostProcess.
    }

    override func onPostProcess() async {
        let features = circleManager.allEntities().compactMap { entity -> MGLPolygonFeature? in
            let updated = makeFeature(for: entity.state)
            entity.circle = updated
            return updated
        }
        circleLayer.setFeatures(features)
    }

    /// The core `circleToRing` generates the ring. The ring is unwrapped (continuous
    /// longitudes around the center), and Mappls (MapLibre GL) accepts longitudes beyond
    /// +/-180, so a circle crossing the antimeridian renders as a single polygon without
    /// splitting.
    private func makeFeature(for state: CircleState) -> MGLPolygonFeature {
        let ring = closeRing(circleToRing(
            center: state.center,
            radiusMeters: state.radiusMeters,
            geodesic: state.geodesic
        ))
        var coords = ring.isEmpty
            ? [CLLocationCoordinate2D(latitude: state.center.latitude, longitude: state.center.longitude)]
            : ring.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        let feature = MGLPolygonFeature(coordinates: &coords, count: UInt(coords.count))
        feature.identifier = "circle-\(state.id)" as NSString
        feature.attributes = [
            CircleLayer.Prop.fillColor: state.fillColor,
            CircleLayer.Prop.strokeColor: state.strokeColor,
            CircleLayer.Prop.strokeWidth: state.strokeWidth,
            CircleLayer.Prop.circleId: state.id
        ]
        return feature
    }
}
