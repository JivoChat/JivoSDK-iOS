//
//  StringExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 08/06/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import TypedTextAttributes

extension Optional where Wrapped == String {
    public var jv_orEmpty: String {
        return self ?? .jv_empty
    }
}

extension String {
    public static let jv_empty = String()
    
    public enum JVSearchingMode {
        case plain
        case email
        case phone
    }
    
    public init(_ value: String?) {
        self = value ?? String()
    }
    
    public var jv_valuable: String? {
        return isEmpty ? nil : self
    }
    
    public var jv_fileExtension: String? {
        if let ext = split(separator: ".").last {
            return String(ext)
        }
        else {
            return nil
        }
    }
    
    public func jv_appendingPathComponent(_ component: String) -> String {
        return NSString(string: self).appendingPathComponent(component)
    }
    
    public func jv_escape() -> String? {
        return addingPercentEncoding(withAllowedCharacters: .alphanumerics)
    }
    
    public func jv_unescape() -> String? {
        return removingPercentEncoding
    }

    public func jv_fromHTML() -> String {
        return NSString(string: self).replacingOccurrences(of: "&nbsp;", with: "\u{00a0}")
    }

    public func jv_unbreakable() -> String {
        return (self as NSString).replacingOccurrences(of: " ", with: " ")
    }

    public func jv_substringFrom(index: Int) -> String {
        if count < index {
            return self
        }
        else {
            let pointer = self.index(startIndex, offsetBy: index)
            return String(self[pointer...])
        }
    }

    public func jv_substringTo(index: Int) -> String {
        if count <= index {
            return self
        }
        else {
            let pointer = self.index(startIndex, offsetBy: index)
            return String(self[...pointer])
        }
    }
    
    public func jv_stringByRemovingSymbols(of set: CharacterSet) -> String {
        return components(separatedBy: set).joined()
    }
    
    public func jv_stringByRemoving(_ strings: [String]) -> String {
        return strings.reduce(self) { result, string in
            return result.replacingOccurrences(of: string, with: "")
        }
    }
    
    public func jv_trimmed(charset: CharacterSet = CharacterSet.whitespacesAndNewlines) -> String {
        return trimmingCharacters(in: charset)
    }
    
    public func jv_trimmedZeros() -> String {
        let zeroCharset = CharacterSet(charactersIn: "\u{0000}")
        let charset = CharacterSet.whitespacesAndNewlines.union(zeroCharset)
        return jv_trimmed(charset: charset)
    }
    
    public func jv_search(_ mode: JVSearchingMode, query: String) -> Bool {
        switch mode {
        case .plain: return lowercased().contains(query.lowercased())
        case .email: return lowercased().contains(query.lowercased())
        case .phone: return jv_extractingPhoneSymbols().contains(query.lowercased())
        }
    }
    
    public func jv_toInt() -> Int {
        return (self as NSString).integerValue
    }

    public func jv_toHexInt() -> UInt64? {
        return jv_valuable.flatMap({ UInt64($0, radix: 16) })
    }
    
    public func jv_toDouble() -> Double {
        return (self as NSString).doubleValue
    }
    
    public func jv_toBool() -> Bool {
        switch self {
        case "true", "1": return true
        case "false", "0": return false
        default: return (self as NSString).boolValue
        }
    }
    
    public func jv_extractingPhoneSymbols() -> String {
        let charset = CharacterSet(charactersIn: "+(0123456789)-")
        return components(separatedBy: charset.inverted).joined()
    }
    
    public func jv_clipBy(_ limit: Int?) -> String {
        guard let limit = limit else { return self }
        guard count >= limit else { return self }
        return jv_substringTo(index: limit) + "…"
    }
    
    public func jv_plain() -> String {
        var result = self
        result = result.replacingOccurrences(of: "\r\n", with: " ")
        result = result.replacingOccurrences(of: "\r", with: " ")
        result = result.replacingOccurrences(of: "\n", with: " ")
        return result
    }
    
    public func jv_oneEmojiString() -> String? {
        let clearString = jv_trimmed()
        return clearString.jv_hasEmojiOnly ? clearString : nil
    }
    
    public func jv_containsSymbols(from characterSet: CharacterSet) -> Bool {
        return components(separatedBy: characterSet).count > 1
    }
    
    public func jv_contains(only symbols: CharacterSet) -> Bool {
        let slices = (self as NSString).components(separatedBy: symbols)
        return (slices.filter(\.isEmpty).count == unicodeScalars.count + 1)
    }

    public func jv_styledWith(lineHeight: CGFloat? = nil, foregroundColor: UIColor? = nil) -> NSAttributedString {
        var attributes = TextAttributes()
        if let value = lineHeight { attributes = attributes.minimumLineHeight(value).maximumLineHeight(value) }
        if let value = foregroundColor { attributes = attributes.foregroundColor(value) }
        return NSAttributedString(string: self, attributes: attributes)
    }

    public func jv_convertToNonBreakable() -> String {
        // replace regular space with non-break space
        return replacingOccurrences(of: " ", with: " ")
    }

    public func jv_quoted() -> String {
        return "\"\(self)\""
    }
    
    public func jv_convertToEmojis() -> String {
        return String(
            String.UnicodeScalarView(
                split(separator: "-")
                    .compactMap { UInt32($0, radix: 16) }
                    .compactMap(UnicodeScalar.init)
            )
        )
    }
    
    public var jv_hasEmojiOnly: Bool {
        guard let firstScalar = unicodeScalars.first else {
            return false
        }
        
        guard #available(iOS 10.2, *) else {
            return firstScalar.jv_isEmoji
        }
        
        for scalarProperties in unicodeScalars.map(\.properties) {
            if scalarProperties.isEmoji, scalarProperties.isEmojiPresentation {
                continue
            }
            else if scalarProperties.isEmojiModifier {
                continue
            }
            else {
                return false
            }
        }
        
        return true
    }
    
    public var jv_hasAnyEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else {
            return false
        }
        
        guard #available(iOS 10.2, *) else {
            return firstScalar.jv_isEmoji
        }
        
        for scalarProperties in unicodeScalars.map(\.properties) {
            if scalarProperties.isEmoji, scalarProperties.isEmojiPresentation {
                return true
            }
            else if scalarProperties.isEmojiModifier {
                return true
            }
            else {
                continue
            }
        }
        
        return false
    }
}

extension String.StringInterpolation {
    public mutating func appendInterpolation(jv_dashed string: String?) {
        appendLiteral(string ?? "-")
    }
}

fileprivate extension UnicodeScalar {
    var jv_isEmoji: Bool {
        switch value {
        case 0x1F600...0x1F64F: return true // Emoticons
        case 0x1F300...0x1F5FF: return true // Misc Symbols and Pictographs
        case 0x1F680...0x1F6FF: return true // Transport and Map
        case 0x1F1E6...0x1F1FF: return true // Regional country flags
        case 0x2600...0x26FF: return true   // Misc symbols
        case 0x2700...0x27BF: return true   // Dingbats
        case 0xFE00...0xFE0F: return true   // Variation Selectors
        case 0x1F900...0x1F9FF: return true // Supplemental Symbols and Pictographs
        case 127000...127600: return true   // Various asian characters
        case 65024...65039: return true     // Variation selector
        case 9100...9300: return true       // Misc items
        case 8400...8447: return true       // Combining Diacritical Marks for Symbols
        default: return false
        }
    }
}