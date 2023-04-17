//
//  NetworkingSubApnsTypes.swift
//  App
//
//  Created by Stan Potemkin on 08.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif
import JMCodingKit

protocol INetworkingSubApns: AnyObject {
    var eventObservable: JVBroadcastTool<NetworkingSubApnsEvent> { get }
}

enum NetworkingSubApnsEvent {
    case payload(Target, String, Date?, UIApplication.State, JsonElement)
}

extension NetworkingSubApnsEvent {
    enum Target {
        case app
        case sdk
    }
}
