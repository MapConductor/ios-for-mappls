import Foundation
import MapConductorCore
import MapplsMap

/// `RasterLayerState` の `userAgent` / `extraHeaders` の規則を
/// [RasterHeaderRuleSet.shared] に出し入れするだけの帳簿。
///
/// 実際にヘッダを載せるのは `MapplsNetworkBridge`（`willSendRequest:` フック）。
/// 他プロバイダのように自前で `MGLNetworkConfiguration.sharedManager.delegate` を
/// 奪っては**いけない** — Mappls SDK 自身が delegate を認証に使っている可能性があり、
/// ブリッジは元の delegate をラップして転送する設計になっている。
final class MapplsRasterHeaderInjector {
    static let shared = MapplsRasterHeaderInjector()

    private init() {}

    /// 登録元 1 つ分の規則を差し替える。
    func apply(states: [RasterLayerState], owner: AnyObject) {
        RasterHeaderRuleSet.shared.setRules(
            RasterHeaderRuleSet.makeRules(from: states),
            owner: owner
        )
        MapplsNetworkBridge.install()
    }

    /// 登録元 1 つ分の規則を外す。
    /// （ブリッジはスキーム修復も担っているので付けたままにする）
    func remove(owner: AnyObject) {
        RasterHeaderRuleSet.shared.removeRules(owner: owner)
    }
}
