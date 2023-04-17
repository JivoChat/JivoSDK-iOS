//
//  NetworkingEventTypes.swift
//  App
//
//  Created by Stan Potemkin on 08.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

protocol INetworkingEventDispatcher: AnyObject {
    func attach(to signal: JVBroadcastTool<NetworkingEvent>)
    func register(decoder: INetworkingEventDecoder?, handler: INetworkingEventHandler)
    func unregister(handler: INetworkingEventHandler)
}

protocol INetworkingEventDecoder: AnyObject {
    func decodeToSubject(event: NetworkingSubject) -> IProtoEventSubject?
    func decodeToBundle(event: NetworkingSubject) -> ProtoEventBundle?
}

protocol INetworkingEventHandler: AnyObject {
    func handleProtoEvent(subject: IProtoEventSubject, context: ProtoEventContext?)
    func handleProtoEvent(transaction: [NetworkingEventBundle])
}

struct NetworkingEventBundle {
    let payload: ProtoEventBundle
    let context: ProtoEventContext?
}
