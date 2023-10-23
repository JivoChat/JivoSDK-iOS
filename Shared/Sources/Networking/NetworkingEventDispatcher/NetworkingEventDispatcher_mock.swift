//
//  NetworkingEventDispatcherMock.swift
//  App
//
//  Created by Stan Potemkin on 08.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
@testable import App

class NetworkingEventDispatcherMock: INetworkingEventDispatcher {
    func attach(to signal: JVBroadcastTool<NetworkingEvent>) {
        fatalError()
    }
    
    func register(decoder: INetworkingEventDecoder?, handler: INetworkingEventHandler) {
        fatalError()
    }
    
    func unregister(handler: INetworkingEventHandler) {
        fatalError()
    }
}
