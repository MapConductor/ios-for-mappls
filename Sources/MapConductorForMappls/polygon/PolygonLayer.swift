import Foundation
import MapplsMap

final class PolygonLayer {
    enum Prop {
        static let fillColor = "fillColor"
        static let strokeColor = "strokeColor"
        static let strokeWidth = "strokeWidth"
        static let zIndex = "zIndex"
        static let polygonId = "polygon_id"
    }

    let sourceId: String
    let fillLayerId: String
    let lineLayerId: String

    private(set) var source: MGLShapeSource?
    private(set) var fillLayer: MGLFillStyleLayer?
    private(set) var lineLayer: MGLLineStyleLayer?

    init(sourceId: String, fillLayerId: String, lineLayerId: String) {
        self.sourceId = sourceId
        self.fillLayerId = fillLayerId
        self.lineLayerId = lineLayerId
    }

    func ensureAdded(to style: MGLStyle) {
        let existingSource = style.source(withIdentifier: sourceId) as? MGLShapeSource
        let existingFill = style.layer(withIdentifier: fillLayerId) as? MGLFillStyleLayer
        let existingLine = style.layer(withIdentifier: lineLayerId) as? MGLLineStyleLayer

        if let existingSource, let existingFill, let existingLine {
            source = existingSource
            fillLayer = existingFill
            lineLayer = existingLine
            return
        }

        let source = existingSource ?? MGLShapeSource(identifier: sourceId, features: [], options: nil)
        if existingSource == nil {
            style.addSource(source)
        }

        let fillLayer = existingFill ?? MGLFillStyleLayer(identifier: fillLayerId, source: source)
        if existingFill == nil {
            fillLayer.fillColor = NSExpression(forKeyPath: Prop.fillColor)
            if fillLayer.responds(to: Selector(("fillSortKey"))) {
                fillLayer.setValue(NSExpression(forKeyPath: Prop.zIndex), forKey: "fillSortKey")
            }
            style.addLayer(fillLayer)
        }

        let lineLayer = existingLine ?? MGLLineStyleLayer(identifier: lineLayerId, source: source)
        if existingLine == nil {
            lineLayer.lineColor = NSExpression(forKeyPath: Prop.strokeColor)
            lineLayer.lineWidth = NSExpression(forKeyPath: Prop.strokeWidth)
            lineLayer.lineJoin = NSExpression(forConstantValue: "round")
            lineLayer.lineCap = NSExpression(forConstantValue: "round")
            if lineLayer.responds(to: Selector(("lineSortKey"))) {
                lineLayer.setValue(NSExpression(forKeyPath: Prop.zIndex), forKey: "lineSortKey")
            }
            style.addLayer(lineLayer)
        }

        self.source = source
        self.fillLayer = fillLayer
        self.lineLayer = lineLayer
    }

    func setFeatures(_ features: [MGLPolygonFeature]) {
        guard let source else { return }
        source.shape = MGLShapeCollectionFeature(shapes: features)
    }

    func remove(from style: MGLStyle) {
        if let fillLayer {
            style.removeLayer(fillLayer)
        }
        if let lineLayer {
            style.removeLayer(lineLayer)
        }
        if let source {
            style.removeSource(source)
        }
        fillLayer = nil
        lineLayer = nil
        source = nil
    }
}
