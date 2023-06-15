//
//  JVDesignFonts.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 11.03.2023.
//

import Foundation
import UIKit

protocol JVIDesignFonts {
    /**
     Examples:
     JVDesign.fonts.resolve(.regular(14), sizing: .callout)
     JVDesign.fonts.resolve(.regular(14...20), sizing: .callout)
     JVDesign.fonts.resolve(.medium(compact: 18, regular: 22), sizing: .body)
     JVDesign.fonts.resolve(.medium(compact: 18...20, regular: 22...25), sizing: .body)
     */
    func resolve(_ meta: JVDesignFontMeta, scaling style: UIFont.TextStyle) -> UIFont
    func emoji(scale: CGFloat?) -> UIFont
    func entypo(ofSize size: CGFloat) -> UIFont?
    func numberOfLines(standard: Int) -> Int
    func scaled(_ value: CGFloat, category: UIFont.TextStyle) -> CGFloat
    func scaled(_ size: CGSize, category: UIFont.TextStyle) -> CGSize
}

extension JVDesignFontMeta {
    static func italics(_ sizing: JVDesignFontSizing) -> Self { .init(weight: .italics, sizing: sizing) }
    static func italics(compact: JVDesignFontSizing, regular: JVDesignFontSizing) -> Self { .init(weight: .italics, compact: compact, regular: regular) }

    static func light(_ sizing: JVDesignFontSizing) -> Self { .init(weight: .light, sizing: sizing) }
    static func light(compact: JVDesignFontSizing, regular: JVDesignFontSizing) -> Self { .init(weight: .light, compact: compact, regular: regular) }
    
    static func regular(_ sizing: JVDesignFontSizing) -> Self { .init(weight: .regular, sizing: sizing) }
    static func regular(compact: JVDesignFontSizing, regular: JVDesignFontSizing) -> Self { .init(weight: .regular, compact: compact, regular: regular) }
    
    static func medium(_ sizing: JVDesignFontSizing) -> Self { .init(weight: .medium, sizing: sizing) }
    static func medium(compact: JVDesignFontSizing, regular: JVDesignFontSizing) -> Self { .init(weight: .medium, compact: compact, regular: regular) }
    
    static func semibold(_ sizing: JVDesignFontSizing) -> Self { .init(weight: .semibold, sizing: sizing) }
    static func semibold(compact: JVDesignFontSizing, regular: JVDesignFontSizing) -> Self { .init(weight: .semibold, compact: compact, regular: regular) }
    
    static func bold(_ sizing: JVDesignFontSizing) -> Self { .init(weight: .bold, sizing: sizing) }
    static func bold(compact: JVDesignFontSizing, regular: JVDesignFontSizing) -> Self { .init(weight: .bold, compact: compact, regular: regular) }
    
    static func heavy(_ sizing: JVDesignFontSizing) -> Self { .init(weight: .heavy, sizing: sizing) }
    static func heavy(compact: JVDesignFontSizing, regular: JVDesignFontSizing) -> Self { .init(weight: .heavy, compact: compact, regular: regular) }
}

enum JVDesignFontWeight {
    case italics
    case light
    case regular
    case medium
    case semibold
    case bold
    case heavy
}

protocol JVDesignFontSizing {
    var jv_lower: CGFloat { get }
    var jv_upper: CGFloat { get }
    var jv_isRange: Bool { get }
}
