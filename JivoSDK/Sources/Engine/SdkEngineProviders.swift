//
//  SdkEngineProviders.swift
//  JivoSDK
//

import Foundation
import JMMarkdownKit


struct SdkEngineProviders {
    let uuidProvider: IUUIDProvider
    let formattingProvider: IFormattingProvider
    let localeProvider: JVILocaleProvider
    
    func mentionRetriever(origin: JMMarkdownMentionOrigin) -> JMMarkdownMentionMeta? {
//        return rosterContext.mentionRetriever(origin: origin)
        return nil
    }
}

struct SdkEngineProvidersFactory {
    let drivers: SdkEngineDrivers
    
    func build() -> SdkEngineProviders {
        let localeProvider = buildLocaleProvider()
        
        return SdkEngineProviders(
            uuidProvider: buildUUIDProvider(),
            formattingProvider: buildFormattingProvider(localeProvider: localeProvider),
            localeProvider: localeProvider
        )
    }
    
    private func buildUUIDProvider() -> IUUIDProvider {
        return UUIDProvider(
            bundle: Bundle(for: Jivo.self),
            package: .sdk,
            keychainDriver: drivers.keychainDriver,
            installationIDPreference: drivers.preferencesDriver.retrieveAccessor(forToken: .installationID))
    }
    
    private func buildLocaleProvider() -> JVILocaleProvider {
        return JVLocaleProvider(
            containingBundle: Bundle(for: Jivo.self),
            activeLocale: (
                JVLocaleProvider.activeLocale == nil
                    ? Locale.current
                    : JVLocaleProvider.activeLocale
            ),
            availableLangs: [.en, .ru, .hy, .es, .pt, .tr]
        )
    }
    
    private func buildFormattingProvider(localeProvider: JVILocaleProvider) -> IFormattingProvider {
        return FormattingProvider(
            preferencesDriver: drivers.preferencesDriver,
            localeProvider: localeProvider,
            systemLocale: Locale.current
        )
    }
}
