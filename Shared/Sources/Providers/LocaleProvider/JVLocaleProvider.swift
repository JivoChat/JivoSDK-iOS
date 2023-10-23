//
//  JVLocaleProvider.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 08/11/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation

enum JVLocaleLang: String {
    case en = "en"
    case ru = "ru"
    case hy = "hy"
    case es = "es"
    case pt = "pt"
    case tr = "tr"
    
    var isRussian: Bool {
        return (self == .ru)
    }
}

protocol JVILocaleProvider: AnyObject {
    var availableLocales: [Locale] { get }
    var activeLocale: Locale { get set }
    var activeLang: JVLocaleLang { get }
    var activeRegion: JVSignupCountry { get }
    var isActiveRussia: Bool { get }
    var isPossibleRussia: Bool { get }
    var isPossibleGlobal: Bool { get }
    func obtainCountries() -> [JVSignupCountry]
}

struct JVSignupCountry {
    let code: String
    let title: String
}

final class JVLocaleProvider: JVILocaleProvider {
    private let containingBundle: Bundle
    public let availableLocales: [Locale]

    private(set) public static var activeLocale: Locale!
    
    public static var baseLocaleBundle: Bundle?

    init(containingBundle: Bundle, activeLocale: Locale, availableLangs: [JVLocaleLang]) {
        if let path = Bundle.main.path(forResource: "Base", ofType: "lproj") {
            JVLocaleProvider.baseLocaleBundle = Bundle(path: path)
        }
        
        self.containingBundle = containingBundle
        self.availableLocales = availableLangs.map(\.rawValue).map(Locale.init)
        self.activeLocale = activeLocale
    }
    
    var activeLocale: Locale {
        get {
            return JVLocaleProvider.activeLocale
        }
        set {
            JVLocaleProvider.activeLocale = newValue
            NotificationCenter.default.post(name: .jvLocaleDidChange, object: containingBundle)
        }
    }
    
    var activeLang: JVLocaleLang {
        let langID = activeLocale.jv_langId
        return JVLocaleLang(rawValue: langID) ?? .en
    }
    
    var activeRegion: JVSignupCountry {
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

    var isActiveRussia: Bool {
        return (activeLang == .ru)
    }

    var isPossibleRussia: Bool {
        let parts = Locale.current.identifier.components(separatedBy: .punctuationCharacters).map { $0.lowercased() }
        return isActiveRussia || parts.contains("ru")
    }

    var isPossibleGlobal: Bool {
        let parts = Locale.current.identifier.components(separatedBy: .punctuationCharacters).map { $0.lowercased() }
        return parts.contains("ua") || !(isPossibleRussia)
    }

    func obtainCountries() -> [JVSignupCountry] {
        let originRegions: [JVSignupCountry] = Locale.isoRegionCodes.compactMap { regionCode in
            let region = Locale.current.localizedString(forRegionCode: regionCode) ?? regionCode
            return JVSignupCountry(code: regionCode, title: region)
        }

        return originRegions.sorted { first, second in
            return (first.title < second.title)
        }
    }
}
