import CoreGraphics
import CoreLocation
import MapplsMap
import MapConductorCore

public final class MapplsMapViewHolder: MapViewHolderProtocol {
    public let mapView: MGLMapView
    public let map: MGLMapView

    init(mapView: MGLMapView) {
        self.mapView = mapView
        self.map = mapView
    }

    public func toScreenOffset(position: GeoPointProtocol) -> CGPoint? {
        let coordinate = CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)
        return mapView.convert(coordinate, toPointTo: mapView)
    }

    public func fromScreenOffsetSync(offset: CGPoint) -> GeoPoint? {
        let coordinate = mapView.convert(offset, toCoordinateFrom: mapView)
        return GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude, altitude: 0)
    }
}
