// swift-tools-version: 5.9
import Foundation
import PackageDescription

let frameworkLibraryType: Product.Library.LibraryType? =
    ProcessInfo.processInfo.environment["MAPCONDUCTOR_BUILD_XCFRAMEWORK"] == "1" ? .dynamic : nil

/// 兄弟パッケージの Package.swift があるかどうか。
///
/// 相対パスを `FileManager` へそのまま渡すと、サンプルアプリの依存として評価された
/// ときに黙って公開リポジトリ側へ落ちる（ios-for-openmobilemaps/Package.swift の
/// コメント参照）。`#filePath` 基準で解決する。
private func siblingPackageExists(_ relativePath: String) -> Bool {
    let manifestDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    let manifest = manifestDir
        .appendingPathComponent(relativePath)
        .appendingPathComponent("Package.swift")
        .standardizedFileURL
    return FileManager.default.fileExists(atPath: manifest.path)
}

let coreDependency: Package.Dependency = siblingPackageExists("../ios-sdk-core")
    ? .package(path: "../ios-sdk-core")
    : .package(url: "https://github.com/MapConductor/ios-sdk-core", from: "1.1.4")

let package = Package(
    name: "mapconductor-for-mappls",
    platforms: [
        // Mappls SDK は iOS 13 以上。コアが 15.1 を要求するのでそちらに合わせる。
        // （ios-sdk-core/Package.swift のコメントを参照。"15.0" は使えない）
        .iOS("15.1"),
    ],
    products: [
        .library(
            name: "MapConductorForMappls",
            type: frameworkLibraryType,
            targets: ["MapConductorForMappls"]
        ),
    ],
    dependencies: [
        coreDependency,
        // Mappls Map iOS SDK（Mapbox GL Native の MGL プレフィックスを保ったフォーク）。
        // バイナリ xcframework + MapplsAPIKit が自動で付いてくる。
        .package(url: "https://github.com/mappls-api/mappls-map-ios-distribution.git", from: "6.1.5"),
        // 認証（*.i.conf / *.i.olf の読み込み）に MapplsAPICoreManager を直接使う
        .package(url: "https://github.com/mappls-api/mappls-api-core-ios-distribution.git", from: "2.1.3"),
    ],
    targets: [
        .target(
            name: "MapConductorForMappls",
            dependencies: [
                .product(name: "MapConductorCore", package: "ios-sdk-core"),
                .product(name: "MapplsMap", package: "mappls-map-ios-distribution"),
                .product(name: "MapplsAPICore", package: "mappls-api-core-ios-distribution"),
            ]
        ),
    ]
)
