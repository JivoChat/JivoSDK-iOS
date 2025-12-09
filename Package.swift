// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let package = Package(
    name: "Jivo",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v11)],
    products: [
        .library(name: "JivoSDK", targets: ["JivoSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/FluidGroup/TypedTextAttributes.git", from: "2.0.0"),
        .package(url: "https://github.com/malcommac/SwiftDate.git", from: "7.0.0"),
        .package(url: "https://github.com/evgenyneu/keychain-swift.git", from: "24.0.0"),
        .package(url: "https://github.com/auth0/JWTDecode.swift.git", exact: "3.1.0"),
        .package(url: "https://github.com/iziz/libPhoneNumber-iOS.git", exact: "1.1.0"),
        .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.1.5"),
        .package(url: "https://github.com/DenTelezhkin/DTCollectionViewManager.git", from: "11.0.0"),
        .package(url: "https://github.com/digital-fireworks/CollectionAndTableViewCompatible.git", exact: "0.2.6"),

        .package(url: "https://github.com/JivoChat/JMDesignKit.git", exact: "2.0.0"),
        .package(url: "https://github.com/JivoChat/JMOnetimeCalculator.git", exact: "2.0.0"),
        .package(url: "https://github.com/JivoChat/SwiftyNSException.git", exact: "2.0.0"),
        .package(url: "https://github.com/JivoChat/JFMarkdownKit.git", exact: "2.0.0"),
        .package(url: "https://github.com/JivoChat/SwiftMime.git", exact: "1.0.0"),
        .package(url: "https://github.com/JivoChat/JMCodingKit.git", exact: "6.0.0"),
        .package(url: "https://github.com/JivoChat/JMImageLoader.git", exact: "2.0.0"),
        .package(url: "https://github.com/JivoChat/JMSidePanelKit.git", exact: "2.0.0"),
        .package(url: "https://github.com/JivoChat/JFWebSocket.git", exact: "3.0.0"),
        .package(url: "https://github.com/JivoChat/JMScalableView.git", exact: "2.0.0"),
        .package(url: "https://github.com/JivoChat/JMRepicKit.git", exact: "2.0.0"),
        .package(url: "https://github.com/JivoChat/JMMarkdownKit.git", exact: "2.0.0"),
        .package(url: "https://github.com/JivoChat/JMTimelineKit.git", exact: "6.0.0"),
        .package(url: "https://github.com/JivoSite/pure-parser.git", exact: "2.0.0"),
        .package(url: "https://github.com/JivoChat/ReachabilitySwift.git", exact: "6.0.0"),
        .package(url: "https://github.com/JivoChat/GzipSwift.git", from: "6.1.1"),
    ],
    targets: [
        .target(
            name: "JivoSDK",
            dependencies: [
                .product(name: "Gzip", package: "GzipSwift"),
                .product(name: "XCGLogger", package: "XCGLogger"),
                .product(name: "JWTDecode", package: "JWTDecode.swift"),
                .product(name: "KeychainSwift", package: "keychain-swift"),
                .product(name: "DTCollectionViewManager", package: "DTCollectionViewManager"),
                .product(name: "Reachability", package: "ReachabilitySwift"),
                .product(name: "SwiftDate", package: "SwiftDate"),
                .product(name: "libPhoneNumber", package: "libPhoneNumber-iOS"),
                .product(name: "PureParser", package: "pure-parser"),
                .product(name: "CollectionAndTableViewCompatible", package: "CollectionAndTableViewCompatible"),

                .product(name: "SwiftyNSException", package: "SwiftyNSException"),
                .product(name: "JFMarkdownKit", package: "JFMarkdownKit"),
                .product(name: "SwiftMime", package: "SwiftMime"),
                .product(name: "JMCodingKit", package: "JMCodingKit"),
                .product(name: "JMSidePanelKit", package: "JMSidePanelKit"),
                .product(name: "JFWebSocket", package: "JFWebSocket"),
                .product(name: "JMScalableView", package: "JMScalableView"),
                .product(name: "JMRepicKit", package: "JMRepicKit"),
                .product(name: "JMMarkdownKit", package: "JMMarkdownKit"),
                .product(name: "JMTimelineKit", package: "JMTimelineKit"),
            ],
            path: ".",
            exclude: [
                "JivoSDK/Sources/Info.plist",
                "Shared/Design/fontello_entypo.ttf",
            ],
            sources: ["JivoSDK/Sources", "Shared/Sources", "Shared/Models", "Shared/Design"],
            resources: [
                .process("JivoSDK/Resources/Assets.xcassets"),
                .process("Shared/Resources/JVDatabase.momd"),
                .copy("Shared/Resources/Fonts/roboto.medium.ttf"),
                .copy("Shared/Resources/Fonts/roboto.regular.ttf"),
                .copy("Shared/Design/fontello_entypo.ttf"),
            ],
            swiftSettings: (
                ProcessInfo.processInfo.environment["JV_USE_XCODE_PRIOR_TO_26"] == "1"
                ? [.define("JV_USE_XCODE_PRIOR_TO_26")]
                : nil
            )
        )
    ]
)
