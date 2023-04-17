//
//  LocaleTypes.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 02/06/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation

public let jv_loc = JVLocalizer(for: NSClassFromString("JivoSDK.JivoSDK"))
internal let loc = jv_loc

public extension Notification.Name {
    static let jvLocaleDidChange = Notification.Name("LocaleDidChange")
}

public enum JVLocalizedMetaMode {
    case key(String)
    case format(String)
    case exact(String)
}

public struct JVLocalizer {
    private let primaryBundle = Bundle.main
    private let secondaryBundle: Bundle?
    
    public init(for classFromBundle: AnyClass? = nil) {
        secondaryBundle = classFromBundle.flatMap(Bundle.init) ?? primaryBundle
    }
    
    public subscript(_ keys: String..., lang lang: String? = nil) -> String {
        var result = String()
        
        for key in keys {
            let relevantBundles: [Bundle]
            if let lang = lang {
                relevantBundles = JVLocaleProvider.collectLangBundles(
                    for: [secondaryBundle, primaryBundle],
                    lang: lang)
            }
            else {
                relevantBundles = JVLocaleProvider.collectLangBundles(
                    for: [JVLocaleProvider.activeBundle, secondaryBundle, primaryBundle],
                    lang: JVLocaleProvider.activeLocale?.jv_langID ?? Locale.current.jv_langID ?? String())
            }
            
            if let value = relevantBundles.jv_findTranslation(key: key) {
                return value
            }
            else if let value = relevantBundles.jv_findTranslation(key: "jivosdk:" + key) {
                return value
            }
            else if lang == nil {
                result = NSLocalizedString(key, comment: String())
            }
            else {
                result = key
            }
            
            if result != key {
                break
            }
        }
        
        return result
    }
    
    public subscript(key key: String, lang: String? = nil) -> String {
        return self[key, lang: lang]
            .replacingOccurrences(of: "%s", with: "%@")
            .replacingOccurrences(of: "$s", with: "$@")
    }
    
    public subscript(format key: String, _ arguments: CVarArg...) -> String {
        let locale = JVLocaleProvider.activeLocale
        return String(format: self[key: key], locale: locale, arguments: arguments)
    }
}

public func JVActiveLocale() -> Locale {
    return JVLocaleProvider.activeLocale
}

fileprivate extension Array where Element == Bundle {
    func jv_findTranslation(key: String) -> String? {
        for bundle in self {
            let value = bundle.localizedString(forKey: key, value: nil, table: nil)
            if value != key {
                return value
            }
        }
        
        return nil
    }
}
