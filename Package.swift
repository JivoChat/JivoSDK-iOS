// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JivoSDK-iOS",
    defaultLocalization: "en",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "JivoSDK-iOS", targets: ["JivoSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/FluidGroup/TypedTextAttributes.git", from: "2.0.0"),
        .package(url: "https://github.com/JivoSite/pure-parser.git", from: "1.0.4"),
        .package(url: "https://github.com/JivoChat/ReachabilitySwift.git", branch: "master"),
        .package(url: "https://github.com/malcommac/SwiftDate.git", from: "7.0.0"),
        .package(url: "https://github.com/evgenyneu/keychain-swift.git", from: "24.0.0"),
        .package(url: "https://github.com/1024jp/GzipSwift.git", from: "6.1.0"),
        .package(url: "https://github.com/auth0/JWTDecode.swift.git", exact: "3.1.0"),
        .package(url: "https://github.com/iziz/libPhoneNumber-iOS.git", exact: "1.1.0"),
        .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.1.5"),
        .package(url: "https://github.com/DenTelezhkin/DTCollectionViewManager.git", from: "11.0.0"),
        .package(url: "https://github.com/digital-fireworks/CollectionAndTableViewCompatible.git", .branch("master")),

        .package(url: "https://github.com/JivoChat/JMOnetimeCalculator.git", .branch("master")),
        .package(url: "https://github.com/JivoChat/SwiftyNSException.git", .branch("main")),
        .package(url: "https://github.com/JivoChat/JFEmojiPicker.git", .branch("master")),
        .package(url: "https://github.com/JivoChat/JMDesignKit.git", .branch("master")),
        .package(url: "https://github.com/JivoChat/JFMarkdownKit.git", .branch("master")),
        .package(url: "https://github.com/JivoChat/SwiftMime.git", .branch("main")),
        .package(url: "https://github.com/JivoChat/JMCodingKit.git", .branch("master")),
        .package(url: "https://github.com/JivoChat/JMImageLoader.git", .branch("main")),
        .package(url: "https://github.com/JivoChat/JMSidePanelKit.git", .branch("master")),
        .package(url: "https://github.com/JivoChat/swift-graylog.git", .branch("master")),
        .package(url: "https://github.com/JivoChat/JFWebSocket.git", .branch("master")),
        .package(url: "https://github.com/JivoChat/JMScalableView.git", .branch("master")),
        .package(url: "https://github.com/JivoChat/JMRepicKit.git", .branch("master")),
        .package(url: "https://github.com/JivoChat/JMMarkdownKit.git", .branch("master")),
        .package(url: "https://github.com/JivoChat/JMTimelineKit.git", .branch("master")),
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
                .product(name: "JFEmojiPicker", package: "JFEmojiPicker"),
                .product(name: "JFMarkdownKit", package: "JFMarkdownKit"),
                .product(name: "SwiftMime", package: "SwiftMime"),
                .product(name: "JMCodingKit", package: "JMCodingKit"),
                .product(name: "JMSidePanelKit", package: "JMSidePanelKit"),
                .product(name: "SwiftGraylog", package: "swift-graylog"),
                .product(name: "JFWebSocket", package: "JFWebSocket"),
                .product(name: "JMScalableView", package: "JMScalableView"),
                .product(name: "JMRepicKit", package: "JMRepicKit"),
                .product(name: "JMMarkdownKit", package: "JMMarkdownKit"),
                .product(name: "JMTimelineKit", package: "JMTimelineKit"),
            ],
            path: "JivoSDK/Sources",
            resources: [
                .process("Shared/Models/JVDatabase.xcdatamodeld"),
                .process("Shared/Design/AssetsDesign.xcassets"),
                .process("Resources/Assets.xcassets"),
                .copy("Shared/Design/fontello_entypo.ttf"),
                .copy("Shared/Resources/Fonts/roboto.medium.ttf"),
                .copy("Shared/Resources/Fonts/roboto.regular.ttf"),
            ]),
    ]
)
