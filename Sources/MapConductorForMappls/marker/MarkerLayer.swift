import Foundation
import MapplsMap
import UIKit

final class MarkerLayer {
    let sourceId: String
    let layerId: String

    private(set) var source: MGLShapeSource?
    private(set) var layer: MGLSymbolStyleLayer?

    init(sourceId: String, layerId: String) {
        self.sourceId = sourceId
        self.layerId = layerId
    }

    func ensureAdded(to style: MGLStyle) {
        let existingSource = style.source(withIdentifier: sourceId) as? MGLShapeSource
        let existingLayer = style.layer(withIdentifier: layerId) as? MGLSymbolStyleLayer

        if let existingSource, let existingLayer {
            source = existingSource
            layer = existingLayer
            return
        }

        let source = existingSource ?? MGLShapeSource(identifier: sourceId, features: [], options: nil)
        if existingSource == nil {
            style.addSource(source)
        }

        let layer = existingLayer ?? MGLSymbolStyleLayer(identifier: layerId, source: source)
        if existingLayer == nil {
            layer.iconImageName = NSExpression(forKeyPath: MapplsMarkerRenderer.Prop.iconId)
            layer.iconAllowsOverlap = NSExpression(forConstantValue: true)
            layer.iconIgnoresPlacement = NSExpression(forConstantValue: true)
            layer.iconAnchor = NSExpression(forConstantValue: "top-left")
            layer.iconOpacity = NSExpression(
                format: "TERNARY(%K == 1, 0, 1)",
                MapplsMarkerRenderer.Prop.isHidden
            )
            // Keep marker icons screen-aligned (like GoogleMaps) to avoid resampling blur when the map rotates/pitches.
            layer.iconRotationAlignment = NSExpression(forConstantValue: "viewport")
            layer.iconPitchAlignment = NSExpression(forConstantValue: "viewport")
            // Mappls renders style images as if they were @1x. We compensate by:
            // - registering images with `UIImage.scale = 1` (points == pixels)
            // - scaling down the symbol by the screen scale to match other providers.
            layer.iconScale = NSExpression(forConstantValue: 1.0 / UIScreen.main.scale)
            layer.iconTranslationAnchor = NSExpression(forConstantValue: "map")
            layer.iconOffset = NSExpression(forKeyPath: MapplsMarkerRenderer.Prop.iconAnchor)
            style.addLayer(layer)
        }

        self.source = source
        self.layer = layer
    }

    func setFeatures(_ features: [MGLPointFeature]) {
        guard let source else { return }
        // Mappls can crash if we mutate a source that is no longer part of the current style
        // (e.g. during/after a style reload). Fail safe by ensuring we still have a layer too.
        guard layer != nil else { return }
        source.shape = MGLShapeCollectionFeature(shapes: features)
    }

    func remove(from style: MGLStyle) {
        if let layer {
            style.removeLayer(layer)
        }
        if let source {
            style.removeSource(source)
        }
        self.layer = nil
        self.source = nil
    }
}
