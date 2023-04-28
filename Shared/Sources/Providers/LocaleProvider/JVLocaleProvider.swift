//
//  JVLocaleProvider.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 08/11/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation

public enum JVLocaleLang: String {
    case en
    case ru
    case hy
    case es
    case pt
    case tr
    
    public var isRussian: Bool {
        return (self == .ru)
    }
}

public protocol JVILocaleProvider: AnyObject {
    var availableLocales: [Locale] { get }
    var activeLocale: Locale { get set }
    var activeLang: JVLocaleLang { get }
    var activeRegion: JVSignupCountry { get }
    var isActiveRussia: Bool { get }
    var isPossibleRussia: Bool { get }
    var isPossibleGlobal: Bool { get }
    func obtainCountries() -> [JVSignupCountry]
}

public struct JVSignupCountry {
    public let code: String
    public let title: String
}

public final class JVLocaleProvider: JVILocaleProvider {
    private let containingBundle: Bundle

    private(set) public static var activeLocale: Locale!
    
    public static var baseLocaleBundle: Bundle?

    public init(containingBundle: Bundle, activeLocale: Locale) {
        if let path = Bundle.main.path(forResource: "Base", ofType: "lproj") {
            JVLocaleProvider.baseLocaleBundle = Bundle(path: path)
        }
        
        self.containingBundle = containingBundle
        self.activeLocale = activeLocale
    }
    
    public var availableLocales: [Locale] {
        return ["en", "ru", "hy", "es", "pt", "tr"].map(Locale.init)
    }
    
    public var activeLocale: Locale {
        get {
            return JVLocaleProvider.activeLocale
        }
        set {
            JVLocaleProvider.activeLocale = newValue
            NotificationCenter.default.post(name: .jvLocaleDidChange, object: containingBundle)
        }
    }
    
    public var activeLang: JVLocaleLang {
        let langID = activeLocale.jv_langId
        return JVLocaleLang(rawValue: langID) ?? .en
    }
    
    public var activeRegion: JVSignupCountry {
        let countries = obtainCountries()
        let code = Locale.current.regionCode

        if let region = countries.first(where: { $0.code == code }) {
            return region
        }
        else if let firstCountry = countries.first {
            return firstCountry
        }
        else {
            abort()
        }
    }

    public var isActiveRussia: Bool {
        return (activeLang == .ru)
    }

    public var isPossibleRussia: Bool {
        let parts = Locale.current.identifier.components(separatedBy: .punctuationCharacters).map { $0.lowercased() }
        return isActiveRussia || parts.contains("ru")
    }

    public var isPossibleGlobal: Bool {
        let parts = Locale.current.identifier.components(separatedBy: .punctuationCharacters).map { $0.lowercased() }
        return parts.contains("ua") || !(isPossibleRussia)
    }

    public func obtainCountries() -> [JVSignupCountry] {
        let originRegions: [JVSignupCountry] = Locale.isoRegionCodes.compactMap { regionCode in
            let region = Locale.current.localizedString(forRegionCode: regionCode) ?? regionCode
            return JVSignupCountry(code: regionCode, title: region)
        }

        return originRegions.sorted { first, second in
            return (first.title < second.title)
        }
    }
}
