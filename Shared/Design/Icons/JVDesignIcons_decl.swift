//
//  JVDesignIcons.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 11.03.2023.
//

import Foundation
import UIKit

protocol JVIDesignIcons {
    func find(logo: JVDesignIconsLogo, lang: String?) -> UIImage?
    func find(preset: JVDesignIconsPreset) -> UIImage?
    func find(preset: JVDesignIconsPreset, pointSize: CGFloat?) -> UIImage?
    func find(asset: JVDesignIconsAsset, rendering: JVDesignAssetRendering) -> UIImage?
    func resolve(systemName: String?, assetName: String, rendering: JVDesignAssetRendering, pointSize: CGFloat?, tintColor: UIColor?) -> UIImage?
}

enum JVDesignIconsLogo {
    case full
    case mini
}

struct JVDesignIconsPreset {
    let systemName: String
    let assetName: String
}

enum JVDesignAssetRendering {
    case original
    case template
}

extension JVDesignIconsPreset {
    static let back = Self.init(systemName: "chevron.left", assetName: "nav_back")
    static let dismiss = Self.init(systemName: "xmark", assetName: "nav_dismiss")
    static let check = Self.init(systemName: "checkmark", assetName: "cell_check")
    static let forward = Self.init(systemName: "chevron.right", assetName: "nav_forward")
    static let dots = Self.init(systemName: "ellipsis", assetName: "dots")
}

struct JVDesignIconsAsset {
    let name: String
}
