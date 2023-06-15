//
//  SdkEngineRepositories.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 20.08.2022.
//

import Foundation


struct SdkEngineRepositories {
    let pushCredentialsRepository: PushCredentialsRepository
}

struct SdkEngineRepositoriesFactory {
    let databaseDriver: JVIDatabaseDriver
    
    func build() -> SdkEngineRepositories {
        return SdkEngineRepositories(
            pushCredentialsRepository: buildPushCredentialsRepository()
        )
    }
    
    private func buildPushCredentialsRepository() -> PushCredentialsRepository {
        return PushCredentialsRepository(databaseDriver: databaseDriver)
    }
}

