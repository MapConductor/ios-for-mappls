import MapConductorCore
import MapplsMap

final class MapplsRasterLayer {
    let source: MGLRasterTileSource
    let layer: MGLRasterStyleLayer

    init(source: MGLRasterTileSource, layer: MGLRasterStyleLayer) {
        self.source = source
        self.layer = layer
    }
}

@MainActor
final class MapplsRasterLayerOverlayRenderer: AbstractRasterLayerOverlayRenderer<MapplsRasterLayer> {
    private weak var mapView: MGLMapView?
    private var style: MGLStyle?

    init(mapView: MGLMapView?) {
        self.mapView = mapView
        super.init()
    }

    func onStyleLoaded(_ style: MGLStyle) {
        self.style = style
    }

    func unbind() {
        style = nil
        mapView = nil
    }

    // Synchronous versions of layer operations to avoid async/await issues
    func createLayerSync(state: RasterLayerState) -> MapplsRasterLayer? {
        guard let style else { return nil }

        let sourceId = "mapconductor-raster-source-\(state.id)"
        let layerId = "mapconductor-raster-layer-\(state.id)"

        // Remove existing layer and source if they already exist
        if let existingLayer = style.layer(withIdentifier: layerId) {
            style.removeLayer(existingLayer)
        }
        if let existingSource = style.source(withIdentifier: sourceId) {
            style.removeSource(existingSource)
        }

        let source = makeTileSource(id: sourceId, source: state.source)
        let layer = MGLRasterStyleLayer(identifier: layerId, source: source)
        layer.rasterOpacity = NSExpression(forConstantValue: state.opacity)
        layer.isVisible = state.visible

        style.addSource(source)
        if state.debug {
            NSLog("[MapConductor] RasterLayer debug mode: id=%@", state.id)
        }
        insertLayer(layer, zIndex: state.zIndex, style: style)

        return MapplsRasterLayer(source: source, layer: layer)
    }

    /// zIndex orders MapConductor raster layers among themselves; the basemap
    /// style's own layers always stay below. Mapping zIndex to a raw style
    /// index put zIndex=0 layers at the bottom of the style stack — beneath
    /// the basemap — so they rendered but were never visible.
    private func insertLayer(_ layer: MGLRasterStyleLayer, zIndex: Int, style: MGLStyle) {
        let conductorIndices = style.layers.indices.filter {
            style.layers[$0].identifier.hasPrefix("mapconductor-raster-layer-")
        }
        if zIndex >= 0, zIndex < conductorIndices.count {
            style.insertLayer(layer, at: UInt(conductorIndices[zIndex]))
        } else {
            style.addLayer(layer)
        }
    }

    func updateLayerSync(
        layer: MapplsRasterLayer,
        current: RasterLayerEntity<MapplsRasterLayer>,
        prev: RasterLayerEntity<MapplsRasterLayer>
    ) -> MapplsRasterLayer? {
        let finger = current.fingerPrint
        let prevFinger = prev.fingerPrint

        guard let style else { return layer }

        if finger.source != prevFinger.source {
            // Recreate layer with new source
            if style.layer(withIdentifier: layer.layer.identifier) != nil {
                style.removeLayer(layer.layer)
            }
            if style.source(withIdentifier: layer.source.identifier) != nil {
                style.removeSource(layer.source)
            }
            return createLayerSync(state: current.state)
        }

        if finger.debug != prevFinger.debug && current.state.debug {
            NSLog("[MapConductor] RasterLayer debug mode: id=%@", current.state.id)
        }

        if finger.zIndex != prevFinger.zIndex {
            style.removeLayer(layer.layer)
            insertLayer(layer.layer, zIndex: current.state.zIndex, style: style)
        }

        if finger.opacity != prevFinger.opacity {
            layer.layer.rasterOpacity = NSExpression(forConstantValue: current.state.opacity)
        }

        if finger.visible != prevFinger.visible {
            layer.layer.isVisible = current.state.visible
        }

        return layer
    }

    func removeLayerSync(entity: RasterLayerEntity<MapplsRasterLayer>) {
        guard let style, let layer = entity.layer else { return }

        if style.layer(withIdentifier: layer.layer.identifier) != nil {
            style.removeLayer(layer.layer)
        }
        if style.source(withIdentifier: layer.source.identifier) != nil {
            style.removeSource(layer.source)
        }
    }

    override func createLayer(state: RasterLayerState) async -> MapplsRasterLayer? {
        // Delegate to synchronous version to avoid async/await issues
        return createLayerSync(state: state)
    }

    override func updateLayerProperties(
        layer: MapplsRasterLayer,
        current: RasterLayerEntity<MapplsRasterLayer>,
        prev: RasterLayerEntity<MapplsRasterLayer>
    ) async -> MapplsRasterLayer? {
        // Delegate to synchronous version to avoid async/await issues
        return updateLayerSync(layer: layer, current: current, prev: prev)
    }

    override func removeLayer(entity: RasterLayerEntity<MapplsRasterLayer>) async {
        // Delegate to synchronous version to avoid async/await issues
        removeLayerSync(entity: entity)
    }

    private func makeTileSource(id: String, source: RasterLayerSource) -> MGLRasterTileSource {
        switch source {
        case let .urlTemplate(template, tileSize, minZoom, maxZoom, _, scheme):
            var options: [MGLTileSourceOption: Any] = [
                .tileSize: NSNumber(value: tileSize)
            ]
            if let minZoom {
                options[.minimumZoomLevel] = NSNumber(value: minZoom)
            }
            if let maxZoom {
                options[.maximumZoomLevel] = NSNumber(value: maxZoom)
            }
            options[.tileCoordinateSystem] =
                NSNumber(
                    value:
                        scheme == .TMS
                            ? MGLTileCoordinateSystem.TMS.rawValue
                            : MGLTileCoordinateSystem.XYZ.rawValue
                )
            return MGLRasterTileSource(identifier: id, tileURLTemplates: [mapplsWhitelistBypass(template)], options: options)
        case let .tileJson(url):
            guard let configUrl = URL(string: url) else {
                assertionFailure("Invalid tileJson URL: \(url)")
                return MGLRasterTileSource(identifier: id, tileURLTemplates: ["about:blank"], options: nil)
            }
            return MGLRasterTileSource(identifier: id, configurationURL: configUrl)
        case let .arcGisService(serviceUrl):
            let base = serviceUrl.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let template = "\(base)/tile/{z}/{y}/{x}"
            var options: [MGLTileSourceOption: Any] = [
                .tileSize: NSNumber(value: RasterLayerSource.defaultTileSize),
                .tileCoordinateSystem: NSNumber(value: MGLTileCoordinateSystem.XYZ.rawValue),
            ]
            return MGLRasterTileSource(identifier: id, tileURLTemplates: [mapplsWhitelistBypass(template)], options: options)
        }
    }
}
