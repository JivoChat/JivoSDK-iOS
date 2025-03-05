//
//  JVDesignIcons.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 11.03.2023.
//

import Foundation
import UIKit

final class JVDesignIcons: JVDesignEnvironmental, JVIDesignIcons {
    func find(logo: JVDesignIconsLogo, lang: String?) -> UIImage? {
        switch (logo, lang) {
        case (.full, "ru"):
            return resolve(
                systemName: nil,
                assetName: "logo_ru",
                rendering: .original,
                pointSize: nil,
                tintColor: nil)
        case (.full, _):
            return resolve(
                systemName: nil,
                assetName: "logo_int",
                rendering: .original,
                pointSize: nil,
                tintColor: nil)
        case (.mini, "ru"):
            return resolve(
                systemName: nil,
                assetName: "mini-logo-ru",
                rendering: .original,
                pointSize: nil,
                tintColor: nil)
        case (.mini, _):
            return resolve(
                systemName: nil,
                assetName: "mini-logo-int",
                rendering: .original,
                pointSize: nil,
                tintColor: nil)
        }
    }
    
    func find(preset: JVDesignIconsPreset) -> UIImage? {
        return find(
            preset: preset,
            pointSize: nil)
    }
    
    func find(preset: JVDesignIconsPreset, pointSize: CGFloat?) -> UIImage? {
        return resolve(
            systemName: preset.systemName,
            assetName: preset.assetName,
            rendering: .original,
            pointSize: pointSize,
            tintColor: nil)
    }
    
    func find(asset: JVDesignIconsAsset, rendering: JVDesignAssetRendering) -> UIImage? {
        return resolve(
            systemName: nil,
            assetName: asset.name,
            rendering: rendering,
            pointSize: nil,
            tintColor: nil)
    }
    
    func resolve(systemName: String?, assetName: String, rendering: JVDesignAssetRendering, pointSize: CGFloat?, tintColor: UIColor?) -> UIImage? {
        if #available(iOS 13.0, *), let systemName = systemName {
            let config: UIImage.SymbolConfiguration
            if let size = pointSize {
                config = UIImage.SymbolConfiguration(pointSize: size, weight: .medium)
            }
            else {
                config = UIImage.SymbolConfiguration(weight: .medium)
            }
            
            if let base = UIImage(systemName: systemName)?.applyingSymbolConfiguration(config) {
                if let color = tintColor {
                    return base.withTintColor(color, renderingMode: .alwaysOriginal)
                }
                else {
                    return base.withRenderingMode(.alwaysTemplate)
                }
            }
        }
        
        if let icon = UIImage.jv_named(assetName) {
            switch rendering {
            case .original:
                return icon.withRenderingMode(.alwaysOriginal)
            case .template:
                return icon.withRenderingMode(.alwaysTemplate)
            }
        }
        
        return nil
    }
}
