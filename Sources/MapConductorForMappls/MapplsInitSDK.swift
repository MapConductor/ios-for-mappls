import Foundation
import MapConductorCore
import MapplsAPICore
import MapplsMap

/// Mappls SDK の初期化（認証コンフィグの読み込みとセッション確立）。
///
/// Mappls v2 系は API キーではなく、コンソールから落とした
/// `<appId>.i.conf` / `<appId>.i.olf`（Bundle ID に紐づく暗号化ファイル）で認証する。
/// アプリはこの 2 ファイルをメインバンドルに入れるだけでよい。
///
/// `MapplsMapView`（SwiftUI）が地図生成前に [ensureInitialized] を呼ぶので、
/// アプリ側で明示的に呼ぶ必要はない。呼び出しは何度でも安全。
public enum MapplsInitSDK {
    private static var initialized = false

    /// バンドルから `*.i.conf` / `*.i.olf` を探して SDK を初期化し、
    /// 認証セッションを張る（地図の初回表示が速くなる。認証自体は
    /// `MapplsMapView` の初期化でも内部的に行われる）。
    public static func ensureInitialized(bundle: Bundle = .main) {
        guard !initialized else { return }
        initialized = true

        let confs = bundle.urls(forResourcesWithExtension: "conf", subdirectory: nil) ?? []
        let olfs = bundle.urls(forResourcesWithExtension: "olf", subdirectory: nil) ?? []
        let conf = confs.first { $0.lastPathComponent.hasSuffix(".i.conf") } ?? confs.first
        let olf = olfs.first { $0.lastPathComponent.hasSuffix(".i.olf") } ?? olfs.first
        if conf == nil || olf == nil {
            MCLog.map("MapplsInitSDK: config files (*.i.conf / *.i.olf) not found in bundle")
        }
        // 外部タイルのスキーム修復フック（MapplsNetworkBridge のコメント参照）
        MapplsNetworkBridge.install()
        MapplsAPICoreManager().initilizeSDK(configPath: conf, olfPath: olf)
        MapplsMapAuthenticator.sharedManager().initializeSDKSession { isSuccess, error in
            if let error {
                MCLog.map("MapplsInitSDK: auth session failed: \(error.localizedDescription)")
            } else {
                MCLog.map("MapplsInitSDK: auth session ready (success=\(isSuccess))")
            }
        }
    }
}
