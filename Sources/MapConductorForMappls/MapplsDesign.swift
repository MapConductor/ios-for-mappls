import Foundation
import MapConductorCore

public protocol MapplsMapDesignTypeProtocol: MapDesignTypeProtocol where Identifier == String {
    /// `setMapplsMapStyle` に渡すスタイル名。空文字は「アカウントの既定スタイル」。
    var styleName: String { get }
}

public typealias MapplsMapDesignType = any MapplsMapDesignTypeProtocol

/// Mappls のスタイルは URL ではなく**スタイル名**で切り替える
/// （`MapplsMapView.setMapplsMapStyle(name)`）。使えるスタイル名はアカウントに
/// 紐づいていて、実行時に `getAvailableMapplsMapStyle()` で取れる。
/// どのアカウントにも既定スタイルが 1 つ設定されている。
/// android の `MapplsDesign` と同じ形。
public struct MapplsDesign: MapplsMapDesignTypeProtocol, Hashable {
    public let id: String
    public let styleName: String
    public let attributionRules: [AttributionRule]

    public init(id: String, styleName: String, attributionRules: [AttributionRule] = []) {
        self.id = id
        self.styleName = styleName
        self.attributionRules = attributionRules
    }

    public func getValue() -> String {
        "mapDesign_id=\(id),style=\(styleName)"
    }

    /// アカウントの既定スタイル（`setMapplsMapStyle` を呼ばずに SDK に任せる）。
    public static let Default = MapplsDesign(id: "default", styleName: "")

    /// 標準（昼）。どのアカウントにも入っている基本スタイル。
    ///
    /// これ以外のスタイルは**契約に紐づく**。コンソールで割り当てた名前を
    /// `MapplsDesign(id:styleName:)` で指定する（契約に無い名前は SDK が
    /// 「style not found」で弾く。実行時の一覧は `getAvailableMapplsMapStyle()`）。
    public static let StandardDay = MapplsDesign(id: "standard_day", styleName: "standard_day")

    /// 標準（夜）。**追加料金の有料オプション**。
    ///
    /// 契約に含まれていないアカウントでは `setMapplsMapStyle` が弾くため、
    /// このリポジトリのサンプルでは選択肢に出していない（サンプルは追加料金を払っていない）。
    /// ライブラリとしては、契約済みのアプリがそのまま使えるよう公開しておく。
    public static let StandardNight = MapplsDesign(id: "standard_night", styleName: "standard_night")

    /// グレー（昼）。**追加料金の有料オプション**。`StandardNight` と同じ扱い。
    public static let GreyDay = MapplsDesign(id: "grey_day", styleName: "grey_day")
}
