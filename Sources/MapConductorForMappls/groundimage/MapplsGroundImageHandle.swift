import Foundation
import MapConductorCore
import MapplsMap

final class MapplsGroundImageHandle {
    let sourceId: String
    let layerId: String
    let imageSource: MGLImageSource
    let rasterLayer: MGLRasterStyleLayer
    let applied: AppliedGroundImage

    init(
        sourceId: String,
        layerId: String,
        imageSource: MGLImageSource,
        rasterLayer: MGLRasterStyleLayer,
        applied: AppliedGroundImage
    ) {
        self.sourceId = sourceId
        self.layerId = layerId
        self.imageSource = imageSource
        self.rasterLayer = rasterLayer
        self.applied = applied
    }

    func copy(
        imageSource: MGLImageSource? = nil,
        rasterLayer: MGLRasterStyleLayer? = nil,
        applied: AppliedGroundImage? = nil
    ) -> MapplsGroundImageHandle {
        MapplsGroundImageHandle(
            sourceId: sourceId,
            layerId: layerId,
            imageSource: imageSource ?? self.imageSource,
            rasterLayer: rasterLayer ?? self.rasterLayer,
            applied: applied ?? self.applied
        )
    }
}

struct AppliedGroundImage: Equatable {
    let bounds: Int
    let image: Int
    let opacity: Int
}
