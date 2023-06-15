//
//  NetworkingEventDispatcher.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 15.09.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

final class NetworkingEventDispatcher: INetworkingEventDispatcher {
    private struct Item {
        weak var decoder: INetworkingEventDecoder?
        weak var handler: INetworkingEventHandler?
    }
    
    private let outputThread: JVIDispatchThread
    private let slicer: INetworkingSlicer?
    
    private let parsingQueue: DispatchQueue
    private var items = [Item]()
    
    init(outputThread: JVIDispatchThread, parsingQueue: DispatchQueue, slicer: INetworkingSlicer?) {
        self.outputThread = outputThread
        self.parsingQueue = parsingQueue
        self.slicer = slicer
        
        slicer?.signal.attachObserver { [unowned self] events in
            self.handleSlicedEvents(events)
        }
    }
    
    func attach(to signal: JVBroadcastTool<NetworkingEvent>) {
        let queue = parsingQueue
        signal.attachObserver { [unowned self] event in
            queue.async {
                self.handleNetworkEvent(event)
            }
        }
    }
    
    func register(decoder: INetworkingEventDecoder?, handler: INetworkingEventHandler) {
        let item = Item(decoder: decoder, handler: handler)
        items.append(item)
    }
    
    func unregister(handler: INetworkingEventHandler) {
        items.removeAll(where: { handler === $0.handler })
    }
    
    private func handleSlicedEvents(_ events: [NetworkingEventBundle]) {
        guard !events.isEmpty
        else {
            return
        }
        
        let handlers = items.compactMap(\.handler)
        return outputThread.async {
            handlers.forEach { handler in
                handler.handleProtoEvent(transaction: events)
            }
        }
    }
    
    private func handleNetworkEvent(_ event: NetworkingEvent) {
        switch event.subject {
        case .socket(.payload(.atom)):
            for decoder in items.compactMap(\.decoder) {
                guard let bundle = decoder.decodeToBundle(event: event.subject)
                else {
                    continue
                }
                
                let contextualBundle = NetworkingEventBundle(payload: bundle, context: event.context)
                slicer?.take(contextualBundle)
            }
        default:
            decodeAndHandle(networkEvent: event)
        }
    }

    private func decodeAndHandle(networkEvent: NetworkingEvent) {
        for decoder in items.compactMap(\.decoder) {
            guard let subject = decoder.decodeToSubject(event: networkEvent.subject)
            else {
                continue
            }
            
            let handlers = items.compactMap(\.handler)
            return outputThread.async {
                for handler in handlers {
                    handler.handleProtoEvent(subject: subject, context: networkEvent.context)
                }
            }
        }
    }
}
