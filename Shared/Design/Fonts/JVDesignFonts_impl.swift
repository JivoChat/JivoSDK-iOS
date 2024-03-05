//
//  JVDesignFonts.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 11.03.2023.
//

import Foundation
import UIKit

fileprivate let f_dynamicFontEnabled = true

final class JVDesignFonts: JVDesignEnvironmental, JVIDesignFonts {
    /**
     Examples:
     JVDesign.fonts.resolve(.regular(14), sizing: .callout)
     JVDesign.fonts.resolve(.regular(14...20), sizing: .callout)
     JVDesign.fonts.resolve(.medium(compact: 18, regular: 22), sizing: .body)
     JVDesign.fonts.resolve(.medium(compact: 18...20, regular: 22...25), sizing: .body)
     */
    func resolve(_ meta: JVDesignFontMeta, scaling style: UIFont.TextStyle) -> UIFont {
        let fontSizing: JVDesignFontSizing = {
            switch environment.effectiveHorizontalClass() {
            case .regular:
                return meta.regularSizing
            case .compact:
                return meta.compactSizing
            case .unspecified:
                return meta.compactSizing
            @unknown default:
                return meta.compactSizing
            }
        }()
        
        let anchorFont: UIFont = jv_convert(meta) { value in
            switch (value.weight, UIAccessibility.isBoldTextEnabled) {
            case (.italics, false), (.italics, true):
                return UIFont.italicSystemFont(ofSize: fontSizing.jv_lower)
            case (.light, false):
                return UIFont.systemFont(ofSize: fontSizing.jv_lower, weight: .light)
            case (.light, true), (.regular, false):
                return UIFont.systemFont(ofSize: fontSizing.jv_lower, weight: .regular)
            case (.regular, true), (.medium, false):
                return UIFont.systemFont(ofSize: fontSizing.jv_lower, weight: .medium)
            case (.medium, true), (.semibold, false):
                return UIFont.systemFont(ofSize: fontSizing.jv_lower, weight: .semibold)
            case (.semibold, true), (.bold, false):
                return UIFont.systemFont(ofSize: fontSizing.jv_lower, weight: .bold)
            case (.bold, true), (.heavy, false):
                return UIFont.systemFont(ofSize: fontSizing.jv_lower, weight: .heavy)
            case (.heavy, true):
                return UIFont.systemFont(ofSize: fontSizing.jv_lower, weight: .black)
            }
        }
        
        guard f_dynamicFontEnabled
        else {
            return anchorFont
        }
        
        let metrics = UIFontMetrics(forTextStyle: style)
        let limit = fontSizing.jv_isRange ? fontSizing.jv_upper : .infinity
        return metrics.scaledFont(for: anchorFont, maximumPointSize: limit)
    }
    
    func emoji(scale: CGFloat?) -> UIFont {
        let fontSize = CGFloat(24 * (scale ?? 1))
        return resolve(.regular(fontSize), scaling: .body)
    }
    
    func entypo(ofSize size: CGFloat) -> UIFont? {
        let name = "fontello_entypo"
        ensureFontLoaded(fontName: name, fileName: name)
        return UIFont(name: name, size: size)
    }
    
    func numberOfLines(standard: Int) -> Int {
        let dynamicDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        
        switch dynamicDescriptor.pointSize {
        case -.infinity ..< 19: return standard
        case 19 ..< 28: return standard + 1
        case 28 ..< .infinity: return standard + 2
        default: abort()
        }
    }
    
    func scaled(_ value: CGFloat, category: UIFont.TextStyle) -> CGFloat {
        return UIFontMetrics(forTextStyle: category).scaledValue(for: value)
    }
    
    func scaled(_ size: CGSize, category: UIFont.TextStyle) -> CGSize {
        return CGSize(
            width: scaled(size.width, category: category),
            height: scaled(size.height, category: category)
        )
    }
    
    private func ensureFontLoaded(fontName: String, fileName: String) {
        guard UIFont.fontNames(forFamilyName: fontName).isEmpty,
              let url = Bundle(for: JVDesign.self).url(forResource: fileName, withExtension: "ttf"),
              let data = try? Data(contentsOf: url),
              let provider = CGDataProvider(data: data as CFData),
              let font = CGFont(provider)
        else {
            return
        }
        
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font, &error) {
            let errorDescription: CFString = CFErrorCopyDescription(error!.takeUnretainedValue())
            let nsError = error!.takeUnretainedValue() as AnyObject as! NSError
            NSException(name: NSExceptionName.internalInconsistencyException, reason: errorDescription as String, userInfo: [NSUnderlyingErrorKey: nsError]).raise()
        }
    }
}

struct JVDesignFontMeta: Equatable {
    let weight: JVDesignFontWeight
    let compactSizing: JVDesignFontSizing
    let regularSizing: JVDesignFontSizing
    
    init(weight: JVDesignFontWeight, sizing: JVDesignFontSizing) {
        self.weight = weight
        self.compactSizing = sizing
        self.regularSizing = sizing
    }
    
    init(weight: JVDesignFontWeight, compact: JVDesignFontSizing, regular: JVDesignFontSizing) {
        self.weight = weight
        self.compactSizing = compact
        self.regularSizing = regular
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.weight == rhs.weight else { return false }
        return true
    }
}

extension CGFloat: JVDesignFontSizing {
    var jv_lower: CGFloat {
        return CGFloat(self)
    }
    
    var jv_upper: CGFloat {
        return CGFloat(self)
    }
    
    var jv_isRange: Bool {
        return false
    }
}

extension Int: JVDesignFontSizing {
    var jv_lower: CGFloat {
        return CGFloat(self)
    }
    
    var jv_upper: CGFloat {
        return CGFloat(self)
    }
    
    var jv_isRange: Bool {
        return false
    }
}

extension ClosedRange: JVDesignFontSizing where Bound == Int {
    var jv_lower: CGFloat {
        return CGFloat(lowerBound)
    }
    
    var jv_upper: CGFloat {
        return CGFloat(upperBound)
    }
    
    var jv_isRange: Bool {
        return true
    }
}
