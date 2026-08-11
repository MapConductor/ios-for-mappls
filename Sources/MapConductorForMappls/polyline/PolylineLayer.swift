import Foundation
import MapplsMap

final class PolylineLayer {
    enum Prop {
        static let strokeColor = "strokeColor"
        static let strokeWidth = "strokeWidth"
        static let zIndex = "zIndex"
        static let polylineId = "polyline_id"
    }

    let sourceId: String
    let layerId: String

    private(set) var source: MGLShapeSource?
    private(set) var layer: MGLLineStyleLayer?

    init(sourceId: String, layerId: String) {
        self.sourceId = sourceId
        self.layerId = layerId
    }

    func ensureAdded(to style: MGLStyle) {
        let existingSource = style.source(withIdentifier: sourceId) as? MGLShapeSource
        let existingLayer = style.layer(withIdentifier: layerId) as? MGLLineStyleLayer

        if let existingSource, let existingLayer {
            source = existingSource
            layer = existingLayer
            return
        }

        let source = existingSource ?? MGLShapeSource(identifier: sourceId, features: [], options: nil)
        if existingSource == nil {
            style.addSource(source)
        }

        let layer = existingLayer ?? MGLLineStyleLayer(identifier: layerId, source: source)
        if existingLayer == nil {
            layer.lineJoin = NSExpression(forConstantValue: "round")
            layer.lineCap = NSExpression(forConstantValue: "round")
            layer.lineColor = NSExpression(forKeyPath: Prop.strokeColor)
            layer.lineWidth = NSExpression(forKeyPath: Prop.strokeWidth)
            if layer.responds(to: Selector(("lineSortKey"))) {
                layer.setValue(NSExpression(forKeyPath: Prop.zIndex), forKey: "lineSortKey")
            }
            style.addLayer(layer)
        }

        self.source = source
        self.layer = layer
    }

    func setFeatures(_ features: [MGLPolylineFeature]) {
        guard let source else { return }
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
