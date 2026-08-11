import CoreLocation
import MapConductorCore
import MapplsMap
import UIKit

func createMapplsPolygons(
    id: String,
    points: [GeoPointProtocol],
    geodesic: Bool,
    fillColor: UIColor,
    strokeColor: UIColor,
    strokeWidth: Double,
    zIndex: Int = 0,
    holes: [[GeoPointProtocol]] = []
) -> [MGLPolygonFeature] {
    // Mappls (MapLibre GL) accepts longitudes beyond +/-180, so the unwrapped rings render
    // as a single polygon (with all holes preserved) even across the antimeridian.
    let rings = buildUnwrappedPolygonRings(
        points: points,
        holes: holes,
        geodesic: geodesic,
        maxSegmentLength: 1000.0
    )
    guard let outerRing = rings.outerRings.first else { return [] }

    let interiorPolygons: [MGLPolygon] = rings.holeRings.compactMap { holeRing in
        let ring = closeRing(ensureClockwiseRing(holeRing))
        guard ring.count >= 4 else { return nil }
        var coordinates = ring.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        return MGLPolygon(coordinates: &coordinates, count: UInt(coordinates.count))
    }

    var coords = closeRing(outerRing).map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    let polygon = interiorPolygons.isEmpty
        ? MGLPolygonFeature(coordinates: &coords, count: UInt(coords.count))
        : MGLPolygonFeature(coordinates: &coords, count: UInt(coords.count), interiorPolygons: interiorPolygons)
    let fid = "polygon-\(id)-0"
    polygon.identifier = fid as NSString
    polygon.attributes = [
        PolygonLayer.Prop.fillColor: fillColor,
        PolygonLayer.Prop.strokeColor: strokeColor,
        PolygonLayer.Prop.strokeWidth: strokeWidth,
        PolygonLayer.Prop.zIndex: zIndex,
        PolygonLayer.Prop.polygonId: id,
        "id": fid
    ]
    return [polygon]
}
