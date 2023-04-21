//
//  JVDesignIcons.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 11.03.2023.
//

import Foundation
import UIKit

public protocol JVIDesignIcons {
    func find(logo: JVDesignIconsLogo) -> UIImage?
    func find(preset: JVDesignIconsPreset) -> UIImage?
    func find(preset: JVDesignIconsPreset, pointSize: CGFloat?) -> UIImage?
    func find(asset: JVDesignIconsAsset, rendering: JVDesignAssetRendering) -> UIImage?
    func resolve(systemName: String?, assetName: String, rendering: JVDesignAssetRendering, pointSize: CGFloat?, tintColor: UIColor?) -> UIImage?
}

public enum JVDesignIconsLogo {
    case full
    case mini
}

public struct JVDesignIconsPreset {
    let systemName: String
    let assetName: String
    
    public init(systemName: String, assetName: String) {
        self.systemName = systemName
        self.assetName = assetName
    }
}

public enum JVDesignAssetRendering {
    case original
    case template
}

extension JVDesignIconsPreset {
    public static let back = Self.init(systemName: "chevron.left", assetName: "nav_back")
    public static let dismiss = Self.init(systemName: "xmark", assetName: "nav_dismiss")
    public static let check = Self.init(systemName: "checkmark", assetName: "cell_check")
    public static let forward = Self.init(systemName: "chevron.right", assetName: "nav_forward")
    public static let dots = Self.init(systemName: "ellipsis", assetName: "dots")
}

public struct JVDesignIconsAsset {
    let name: String
    
    public init(name: String) {
        self.name = name
    }
}
