//
//  SdkSessionSubStorage.swift
//  SDK
//
//  Created by Stan Potemkin on 01.02.2023.
//

import Foundation
import JivoFoundation
import JMCodingKit


enum SdkSessionSubStorageEvent {
}

protocol ISdkSessionSubStorage: IBaseSubStorage {
    var eventSignal: JVBroadcastTool<SdkSessionSubStorageEvent> { get }
}

class SdkSessionSubStorage: CommonSubStorage, ISdkSessionSubStorage {
    let eventSignal = JVBroadcastTool<SdkSessionSubStorageEvent>()
    
    init(
        clientContext: ISdkClientContext,
        databaseDriver: JVIDatabaseDriver
    ) {
        super.init(
            userContext: clientContext,
            databaseDriver: databaseDriver
        )
    }
}
