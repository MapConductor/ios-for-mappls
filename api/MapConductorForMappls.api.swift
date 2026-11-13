import Combine
import CoreGraphics
import CoreLocation
import Foundation
import MapConductorCore
import MapplsAPICore
import MapplsMap
import QuartzCore
import Swift
import SwiftUI
import UIKit
import _Concurrency
import _StringProcessing
import _SwiftConcurrencyShims
public protocol MapplsMapDesignTypeProtocol : MapConductorCore::MapDesignTypeProtocol where Self.Identifier == Swift::String {
  var styleName: Swift::String { get }
}
public typealias MapplsMapDesignType = any MapConductorForMappls::MapplsMapDesignTypeProtocol
public struct MapplsDesign : MapConductorForMappls::MapplsMapDesignTypeProtocol, Swift::Hashable {
  public let id: Swift::String
  public let styleName: Swift::String
  public let attributionRules: [MapConductorCore::AttributionRule]
  public init(id: Swift::String, styleName: Swift::String, attributionRules: [MapConductorCore::AttributionRule] = [])
  public func getValue() -> Swift::String
  public static let Default: MapConductorForMappls::MapplsDesign
  public static let StandardDay: MapConductorForMappls::MapplsDesign
  public static let StandardNight: MapConductorForMappls::MapplsDesign
  public static let GreyDay: MapConductorForMappls::MapplsDesign
  public static func == (a: MapConductorForMappls::MapplsDesign, b: MapConductorForMappls::MapplsDesign) -> Swift::Bool
  public typealias Identifier = Swift::String
  public func hash(into hasher: inout Swift::Hasher)
  public var hashValue: Swift::Int {
    get
  }
}
public enum MapplsInitSDK {
  public static func ensureInitialized(bundle: Foundation::Bundle = .main)
}
@_Concurrency::MainActor @preconcurrency public struct MapplsMapView : SwiftUICore::View {
  @_Concurrency::MainActor @preconcurrency public init(state: MapConductorForMappls::MapplsViewState, cameraRestriction: MapConductorCore::CameraRestriction? = nil, onMapLoaded: MapConductorCore::OnMapLoadedHandler<MapConductorForMappls::MapplsViewState>? = nil, onMapClick: MapConductorCore::OnMapEventHandler? = nil, onMapLongClick: MapConductorCore::OnMapEventHandler? = nil, onCameraMoveStart: MapConductorCore::OnCameraMoveHandler? = nil, onCameraMove: MapConductorCore::OnCameraMoveHandler? = nil, onCameraMoveEnd: MapConductorCore::OnCameraMoveHandler? = nil, sdkInitialize: (() -> Swift::Void)? = nil, style: (any MapConductorCore::MapViewStyle)? = nil, onStyleDiagnostics: (([Swift::String]) -> Swift::Void)? = nil, @MapConductorCore::MapViewContentBuilder content: @escaping () -> MapConductorCore::MapViewContent = { MapViewContent() })
  @_Concurrency::MainActor @preconcurrency public var body: some SwiftUICore::View {
    get
  }
  public typealias Body = @_opaqueReturnTypeOf("$s21MapConductorForMappls0dA4ViewV4bodyQrvp", 0) __
}
public typealias MapplsActualMarker = MapplsMap::MGLPointFeature
public typealias MapplsActualPolyline = MapplsMap::MGLPolyline
public typealias MapplsActualCircle = MapplsMap::MGLPolygon
public typealias MapplsActualPolygon = MapplsMap::MGLPolygon
final public class MapplsViewState : MapConductorCore::MapViewState<MapConductorForMappls::MapplsMapDesignType> {
  final public var mapViewHolder: MapConductorForMappls::MapplsMapViewHolder? {
    get
  }
  override final public var mapDesignType: MapConductorForMappls::MapplsMapDesignType {
    get
    set
  }
  public init(id: Swift::String, mapDesignType: MapConductorForMappls::MapplsMapDesignType = MapplsDesign.Default, cameraPosition: MapConductorCore::MapCameraPosition = .Default, uiSettings: MapConductorCore::MapUISettings = MapUISettings())
  convenience public init(mapDesignType: MapConductorForMappls::MapplsMapDesignType = MapplsDesign.Default, cameraPosition: MapConductorCore::MapCameraPosition = .Default, uiSettings: MapConductorCore::MapUISettings = MapUISettings())
  override final public func getMapViewHolder() -> MapConductorCore::AnyMapViewHolder?
  @objc deinit
}
@_hasMissingDesignatedInitializers final public class MapplsMapViewHolder : MapConductorCore::MapViewHolderProtocol {
  final public let mapView: MapplsMap::MGLMapView
  final public let map: MapplsMap::MGLMapView
  final public func toScreenOffset(position: any MapConductorCore::GeoPointProtocol) -> CoreFoundation::CGPoint?
  final public func fromScreenOffsetSync(offset: CoreFoundation::CGPoint) -> MapConductorCore::GeoPoint?
  public typealias ActualMap = MapplsMap::MGLMapView
  public typealias ActualMapView = MapplsMap::MGLMapView
  @objc deinit
}
extension MapConductorForMappls::MapplsMapView : Swift::Sendable {}
