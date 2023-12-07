//
//  Networking.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 03.08.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

enum NetworkingUrlScope {
    case original
    case replace(String)
}

typealias NetworkingUrlBuilder = (URL, String?, NetworkingUrlScope, String?) -> URL?

final class Networking: INetworking {
    private struct RequestMeta {
        let kindID: UUID
        let context: Any?
    }
    
    let context: INetworkingContext
    let eventObservable = JVBroadcastTool<NetworkingEvent>()
    
    private let baseURL: URL
    private let subSocket: INetworkingSubSocket?
    private let subRest: INetworkingSubRest?
    private let subApns: INetworkingSubApns?
    private let localeProvider: JVILocaleProvider
    private let uuidProvider: IUUIDProvider
    private let preferencesDriver: IPreferencesDriver
    private let endpointAccessor: IKeychainAccessor
    private let jsonPrivacyTool: JVJsonPrivacyTool
    private let urlBuilder: NetworkingUrlBuilder

    private var socketEventObserver: JVBroadcastObserver<NetworkingSubSocketEvent>?
    private var restEventObserver: JVBroadcastObserver<NetworkingSubRestEvent>?
    private var apnsEventObserver: JVBroadcastObserver<NetworkingSubApnsEvent>?
    @AtomicMut private var requestMetas: [UUID: RequestMeta]
    
    private let defaultBacksignal = JVBroadcastTool<Any>()
    private var currentObject: Any?
    private var contextStorage = [UUID: ProtoEventContext]()
    private var recentBacksignal: JVBroadcastTool<Any>?

    init(
        subSocket: INetworkingSubSocket?,
        subRest: INetworkingSubRest?,
        subApns: INetworkingSubApns?,
        localeProvider: JVILocaleProvider,
        uuidProvider: IUUIDProvider,
        preferencesDriver: IPreferencesDriver,
        keychainDriver: IKeychainDriver,
        jsonPrivacyTool: JVJsonPrivacyTool,
        urlBuilder: @escaping NetworkingUrlBuilder
    ) {
        context = NetworkingContext(
            localeProvider: localeProvider
        )
        
        baseURL = constructBaseURL(
            context: context,
            preferencesDriver: preferencesDriver,
            module: "api")
        
        self.subSocket = subSocket
        self.subRest = subRest
        self.subApns = subApns
        self.localeProvider = localeProvider
        self.uuidProvider = uuidProvider
        self.preferencesDriver = preferencesDriver
        self.endpointAccessor = keychainDriver.retrieveAccessor(forToken: .endpoint)
        self.jsonPrivacyTool = jsonPrivacyTool
        self.urlBuilder = urlBuilder

        requestMetas = Dictionary()
        
        socketEventObserver = subSocket?.eventObservable.addObserver { [unowned self] event in
            self.handleSocketEvent(event: event)
        }
        
        restEventObserver = subRest?.eventObservable.addObserver { [unowned self] event in
            self.handleRestEvent(event: event)
        }
    
        apnsEventObserver = subApns?.eventObservable.addObserver { [unowned self] event in
            self.handleApnsEvent(event: event)
        }
    }
    
    var isConnecting: Bool {
        return subSocket?.isConnecting ?? false
    }
    
    var isConnected: Bool {
        return subSocket?.isConnected ?? false
    }
    
    var observable: JVBroadcastTool<Any> {
        return recentBacksignal ?? defaultBacksignal
    }
    
    var primaryDomain: String {
        return context.primaryDomain
    }
    
    func setPreferredDomain(_ domain: NetworkingDomain) {
        context.setPreferredDomain(domain)
    }
    
    final func baseURL(module: String) -> URL {
        return constructBaseURL(
            context: context,
            preferencesDriver: preferencesDriver,
            module: module)
    }
    
    func connect(url: URL) {
        subSocket?.connect(
            to: url,
            withHeaders: [
                "User-Agent": uuidProvider.userAgentBrief
            ])
    }
    
    func disconnect() {
        subSocket?.disconnect()
    }
    
    func contextual(object: Any?) -> Self {
        currentObject = object
        return self
    }
    
    func flushContext() -> UUID {
        let backsignal = JVBroadcastTool<Any>()
        recentBacksignal = backsignal
        
        let contextID = UUID()
        contextStorage[contextID] = ProtoEventContext(object: currentObject, backsignal: backsignal)
        currentObject = nil
        return contextID
    }

    func silent() {
    }

    func send(output: NetworkingOutputSubject, caching: NetworkingOutputCaching) -> Self {
        let requestID = UUID()
        
        switch output {
        case .raw(let message):
            subSocket?.sendRaw(
                message: message,
                supportsCaching: (caching != .disabled))
            
        case .legacy(let name, let params):
            subSocket?.sendLegacy(
                name: name,
                body: params.reduce(JsonElement()) { $0.merged(with: $1) },
                supportsCaching: (caching != .disabled))
            
        case .rpc(let kindID, let method, let params, let contextID):
            if let kindID = kindID {
                let object = contextStorage.removeValue(forKey: contextID)
                recentBacksignal = object?.backsignal ?? defaultBacksignal
                $requestMetas.mutate { $0[requestID] = RequestMeta(kindID: kindID, context: object) }
            }
            else {
                recentBacksignal = defaultBacksignal
            }
            
            subSocket?.sendRPC(
                requestID: requestID,
                method: method,
                body: params.reduce(JsonElement()) { $0.merged(with: $1) },
                supportsCaching: (caching != .disabled))
            
        case .atom(let type, let context, let id, let data):
            var json = JsonElement.ordict([:])
            json["type"] = JsonElement.string(type)
            context.flatMap { json["context"] = JsonElement.string($0) }
            id.flatMap { json["id"] = JsonElement.string($0) }
            data.flatMap { json["data"] = JsonElement.string($0) }
//            model.to.flatMap { json["to"] = JsonElement.string($0) }
//            model.from.flatMap { json["from"] = JsonElement.string($0) }
//            model.parent.flatMap { json["parent"] = JsonElement.string($0) }

            subSocket?.sendAtom(
                json: json,
                supportsCaching: (caching != .disabled))
            
        case .rest(let kindID, let target, let options, let contextID):
            let resolvedURL: URL
            switch target {
            case .url(let link):
                if let url = URL(string: link) {
                    resolvedURL = url
                }
                else {
                    let chain = journal {"Failed constructing the absolute url"}
                    chain.nextLine { "Link: " + String(describing: link) }
                    return self
                }
            case .build(.chatServer, let path):
                if let scopedURL = urlBuilder(baseURL, endpointAccessor.string, .original, path) {
                    resolvedURL = scopedURL
                }
                else {
                    let chain = journal {"Failed constructing the scoped url for chatServer"}
                    chain.nextLine { [value = baseURL] in "Base URL: " + String(describing: value) }
                    chain.nextLine { [value = endpointAccessor.string] in "Endpoint: " + String(describing: value) }
                    chain.nextLine { "Path: " + String(describing: path) }
                    return self
                }
            case .build(let scope, let path) where scope.kind == .specific:
                if let scopedURL = urlBuilder(baseURL, endpointAccessor.string, .replace(scope.value), path) {
                    resolvedURL = scopedURL
                }
                else {
                    let chain = journal {"Failed constructing the scoped url for \(scope)"}
                    chain.journal { [value = baseURL] in "baseURL: " + String(describing: value) }
                    chain.journal { "path: " + String(describing: path) }
                    return self
                }
            case .build:
                resolvedURL = baseURL
                assertionFailure()
            }
            
            if let kindID = kindID {
                let object = contextStorage.removeValue(forKey: contextID)
                recentBacksignal = object?.backsignal ?? defaultBacksignal
                $requestMetas.mutate { $0[requestID] = RequestMeta(kindID: kindID, context: object) }
            }
            else {
                recentBacksignal = defaultBacksignal
            }

            subRest?.request(
                requestID: requestID,
                url: resolvedURL,
                options: options)
            
        case .file(let file, let upload, let callback):
            subRest?.upload(
                file: file,
                config: upload,
                callback: callback)
            
        case .media(let media, let upload, let callback):
            subRest?.upload(
                media: media,
                config: upload,
                callback: callback)
        }
        
        return self
    }
    
    func startCaching() {
        subSocket?.startCaching()
    }
    
    func stopCaching(flush: Bool) {
        subSocket?.stopCaching(flush: flush)
    }
    
    func pauseListening() {
        subSocket?.pauseListening()
    }
    
    func resumeListening(flush: Bool) {
        subSocket?.resumeListening(flush: flush)
    }
    
    func cancelActiveRequests() {
        subRest?.cancelActiveRequests()
    }
    
    func cancelBackgroundRequests() {
        subRest?.cancelBackgroundRequests()
    }
    
    private func handleSocketEvent(event: NetworkingSubSocketEvent) {
        switch event {
        case .open(let id):
            journal {"Networking: socked opened\nsocket-id[\(id)]"}
            proceed(subject: .socket(event), context: nil)
        case .payload(.raw), .payload(.legacy), .payload(.atom), .payload(.unknown):
            proceed(subject: .socket(event), context: nil)
        case let .payload(.rpc(method, json)):
            proceed(subject: .socket(.payload(.rpc(method, json))), context: nil)
        case let .payload(.rpcAck(requestID, status, json)):
            guard let meta: RequestMeta = $requestMetas.mutate({ $0.removeValue(forKey: requestID) }) else { return }
            let context = meta.context as? ProtoEventContext
            proceed(subject: .socket(.payload(.rpcAck(meta.kindID, status, json))), context: context)
        case .close(let id, _, _, _):
            journal {"Networking: socked closed\nsocket-id[\(id)]"}
            proceed(subject: .socket(event), context: nil)
        }
    }
    
    private func handleRestEvent(event: NetworkingSubRestEvent) {
        switch event {
        case .response(let requestID, let url, let response):
            guard let meta = $requestMetas.mutate({ $0.removeValue(forKey: requestID) }) else { return }
            let context = meta.context as? ProtoEventContext
            proceed(subject: .rest(.response(meta.kindID, url, response)), context: context)
        }
    }
    
    private func handleApnsEvent(event: NetworkingSubApnsEvent) {
        proceed(subject: .apns(event), context: nil)
    }
    
    private func proceed(subject: NetworkingSubject, context: ProtoEventContext?) {
        let networkEvent = NetworkingEvent(subject: subject, context: context)
        eventObservable.broadcast(networkEvent)
    }
}

fileprivate func constructBaseURL(context: INetworkingContext, preferencesDriver: IPreferencesDriver, module: String) -> URL {
    let host = context.primaryDomain
    let defaultValue = URL(string: "https://\(module).\(host)")!
    
    if let prefix = preferencesDriver.retrieveAccessor(forToken: .server).string, !prefix.isEmpty {
        return URL(string: "https://\(module).\(prefix).dev.\(host)") ?? defaultValue
    }
    else {
        return defaultValue
    }
}

