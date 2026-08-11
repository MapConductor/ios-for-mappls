import Foundation
import MapConductorCore
import MapplsMap

/// Mappls SDK のネットワーク層の 2 つの問題をまとめて塞ぐフック。
///
/// 1. **外部 URL のスキーム欠落。** この SDK は mappls / mapmyindia 以外のタイル URL を
///    `gibs.earthdata.nasa.gov/...` のような**スキームなし**でリクエストに載せるため、
///    CFNetwork が `unsupported URL (-1002)` で落とす（実測）。そのままでは
///    ラスタレイヤ・GeoJSON レイヤ・ヒートマップ・タイル方式マーカーの外部/ローカル
///    タイルが一切取得されない。ここで `https://`（127.0.0.1 / localhost は `http://`）を
///    補って修復する。android 側の `MapplsHttpBridge` と同じ役割。
/// 2. **ヘッダ規則の適用。** `RasterLayerState` の `userAgent` / `extraHeaders`
///    （[RasterHeaderRuleSet.shared]）をラスタタイルの配信ホスト宛にだけ載せる。
///
/// 差し込み先は `MGLNetworkConfiguration.sharedManager.delegate`（プロセスで 1 つ）。
/// SDK 自身が認証のために delegate を使っている可能性があるので、**奪わずにラップして
/// 転送する**。未知のセレクタは `forwardingTarget` で元の delegate へ流す。
/// 外部タイル URL をこの SDK のホワイトリスト検査から逃がす目印を付ける。
///
/// この SDK のネイティブ HTTP 層は、URL に `mappls` / `mapmyindia` を含まない
/// リクエストを**ホスト名だけに切り落として**送る（実測: `gibs.earthdata.nasa.gov` の
/// ようにパス・クエリが消え、GIBS はルートで世界画像を返すので「全タイルが世界図」
/// という壊れ方をする）。切り落とされた後ではフックでも復元できないため、
/// テンプレートの段階でダミークエリ `mcmappls=1` を足して検査を素通りさせる。
/// 配信サーバは未知のクエリパラメータを無視するので実害はない。
func mapplsWhitelistBypass(_ template: String) -> String {
    if template.contains("mappls") || template.contains("mapmyindia") { return template }
    return template + (template.contains("?") ? "&" : "?") + "mcmappls=1"
}

final class MapplsNetworkBridge: NSObject, MGLNetworkConfigurationDelegate {
    static let shared = MapplsNetworkBridge()

    /// ラップした元の delegate（SDK が設定したもの）。weak にすると SDK 側が
    /// 参照を手放した瞬間に消えるので strong で保持する。
    private var upstream: MGLNetworkConfigurationDelegate?

    override private init() {
        super.init()
    }

    /// フックを差す。SDK が後から delegate を差し替えることがあるので、
    /// 地図の生成・スタイル読込のたびに呼んでよい（差し替えを検知して再ラップする）。
    static func install() {
        shared.installIfNeeded()
    }

    private func installIfNeeded() {
        let manager = MGLNetworkConfiguration.sharedManager
        if manager.delegate === self { return }
        upstream = manager.delegate
        manager.delegate = self
    }

    // MARK: - MGLNetworkConfigurationDelegate

    /// - Important: セレクタ名を明示している。`MGLNetworkConfigurationDelegate` の
    ///   メソッドはすべて `@optional` なので、Swift 側の名前が `willSendRequest:` に
    ///   束ならなくてもコンパイルは通り、**黙って呼ばれないだけ**になる。
    @objc(willSendRequest:)
    func willSend(_ request: NSMutableURLRequest) -> NSMutableURLRequest {
        // 先に元の delegate（SDK の認証ヘッダ付与など）へ通す
        let request = upstream?.willSend?(request) ?? request

        // スキーム欠落の修復
        if let url = request.url {
            let s = url.absoluteString
            let lower = s.lowercased()
            let hasScheme =
                lower.hasPrefix("http://") || lower.hasPrefix("https://") ||
                lower.hasPrefix("file:") || lower.hasPrefix("data:") ||
                lower.hasPrefix("asset://") || lower.hasPrefix("local://") ||
                lower.hasPrefix("mappls://")
            if !hasScheme {
                // ローカルタイルサーバ（ヒートマップ等）は http、それ以外は https
                let scheme = (lower.hasPrefix("127.0.0.1") || lower.hasPrefix("localhost")) ? "http://" : "https://"
                if let fixed = URL(string: scheme + s) {
                    request.url = fixed
                }
            }
        }

        // ヘッダ規則（配信ホストが一致するリクエストにだけ載せる）
        if let url = request.url, let match = RasterHeaderRuleSet.shared.headers(for: url) {
            if let userAgent = match.userAgent {
                request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            }
            for (key, value) in match.extraHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        return request
    }

    // MARK: - 元の delegate への転送

    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) { return true }
        return upstream?.responds(to: aSelector) ?? false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if let upstream, upstream.responds(to: aSelector) { return upstream }
        return super.forwardingTarget(for: aSelector)
    }
}
