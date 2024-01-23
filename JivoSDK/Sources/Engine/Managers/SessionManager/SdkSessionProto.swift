//
//  SdkSessionProto.swift
//  JivoMobile-dev
//
//  Created by Anton Karpushko on 09.09.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit


enum SessionProtoEventSubject: IProtoEventSubject {
    case connectionConfig(ProtoEventSubjectPayload.ConnectionConfig)
    case pushRegistration(ProtoEventSubjectPayload.PushRegistration)
    case socketOpen
    case socketClose(kind: APIConnectionCloseCode, error: Error?)
}

extension ProtoTransactionKind {
    enum SessionValue: String {
        case socket
        case me
    }
    
    static func session(_ value: SessionValue) -> ProtoTransactionKind {
        caseFor(value)
    }
}

enum MeTransactionSubject: IProtoEventSubject {
    case meId(id: String)
    case meUrlPath(path: String)
    case meHistory(lastMessageId: Int?)
}

protocol ISdkSessionProto: IProto {
    func requestConfig(channelId: String) -> INetworking

    @discardableResult
    func connectToLive(host: String, port: Int?, credentials: SdkSessionLiveCredentials) -> Bool
    
}

enum SdkSessionLiveCredentials {
    case ids(siteId: Int, widgetId: String, clientToken: String?)
    case path(String)
}

class SdkSessionProto: BaseProto, ISdkSessionProto {
    private let localeProvider: JVILocaleProvider
    
    // MARK: Private properties
    
    
    init(
         clientContext: ISdkClientContext?,
         socketUUID: UUID,
         networking: INetworking,
         networkingHelper: INetworkingHelper,
         keychainTokenAccessor: IKeychainAccessor,
         uuidProvider: IUUIDProvider,
         localeProvider: JVILocaleProvider) {
             self.localeProvider = localeProvider
             
             super.init(userContext: clientContext, socketUUID: socketUUID, networking: networking, networkingHelper: networkingHelper, keychainTokenAccessor: keychainTokenAccessor, uuidProvider: uuidProvider)
    }
    
    // MARK: Public methods
    
    func requestConfig(channelId: String) -> INetworking {
        let endpoint = "https://sdk.\(networking.primaryDomain)/config/\(channelId)"
        journal {"API: request config at\n\(endpoint)"}
        
        let options = RestRequestOptions(
            behavior: .regular,
            method: .get,
            headers: [:],
            query: Array(),
            body: .omit
        )
        
        let contextID = networking.flushContext()
        _ = networking.send(
            output: .rest(
                kindID: ProtoEventSubjectPayload.ConnectionConfig.kindId,
                target: .url(endpoint),
                options: options,
                contextID: contextID
            ),
            caching: .auto)
        
        return networking
    }
    
    func connectToLive(host: String, port: Int?, credentials: SdkSessionLiveCredentials) -> Bool {
        guard let url = URL(string: host),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return false
        }
        
        components.port = port?.jv_valuable
        components.path = "/atom"
        
        switch credentials {
        case .ids(let siteId, let widgetId, let clientToken):
            components.path += "/\(siteId):\(widgetId)"
            components.jv_setQuery(mapping: ["token": clientToken])
        case .path(let path):
            components.path += path
        }
        
        if let finalUrl = components.url {
            networking.connect(url: finalUrl)
            return true
        }
        else {
            return false
        }
    }
    
    override func decodeToSubject(event: NetworkingSubject) -> IProtoEventSubject? {
        switch event {
        case .socket(.open):
            return SessionProtoEventSubject.socketOpen
        case .socket(let .close(identifier, code, reason, error)):
            return decodeSocketClose(identifier: identifier, code: code, reason: reason, error: error)
        case let .rest(.response(ProtoEventSubjectPayload.ConnectionConfig.kindId, _, response)):
            return decodeConnectionConfig(response)
        default:
            return super.decodeToSubject(event: event)
        }
    }
    
    override func decodeToBundle(event: NetworkingSubject) -> ProtoEventBundle? {
        switch event {
        case .socket(.payload(.atom("atom/me.id", let model))):
            return decodeAtomMeId(model)
        case .socket(.payload(.atom("atom/me.url.path", let model))):
            return decodeAtomMeUrlPath(model)
        case .socket(.payload(.atom("atom/me.history", let model))):
            return decodeAtomMeHistory(model)
        default:
            return super.decodeToBundle(event: event)
        }
    }
    
    private func decodeConnectionConfig(_ response: NetworkingSubRestEvent.Response) -> SessionProtoEventSubject {
        let meta = ProtoEventSubjectPayload.ConnectionConfig(
            status: response.status,
            body: .init(
                siteId: response.body["site_id"].intValue,
                chatserverHost: response.body["chatserver_host"].stringValue,
                apiHost: response.body["api_host"].stringValue,
                filesHost: response.body["files_host"].stringValue,
                isLicensed: response.body["license"].bool,
                rateConfig: .init(json: response.body["rate_settings"])
            )
        )
        
        return .connectionConfig(meta)
    }
    
    private func decodeSocketClose(identifier: UUID, code: Int, reason: String, error: Error?) -> SessionProtoEventSubject? {
        switch code {
        case connectionNormalCloseCode:
            return SessionProtoEventSubject.socketClose(kind: .connectionBreak, error: error)
        case connectionSessionEndCode where reason.lowercased().contains("blacklist"):
            return SessionProtoEventSubject.socketClose(kind: .blacklist, error: error)
        case connectionSessionEndCode where error == nil:
            return SessionProtoEventSubject.socketClose(kind: .sessionEnd, error: error)
        case connectionAbsentCode:
            return SessionProtoEventSubject.socketClose(kind: .missingConnection, error: error)
        case connectionNotReachableCode:
            return SessionProtoEventSubject.socketClose(kind: .missingConnection, error: error)
        case connectionMissingPongCode:
            return SessionProtoEventSubject.socketClose(kind: .missingConnection, error: error)
        default:
            return SessionProtoEventSubject.socketClose(kind: .unknown(code), error: error)
        }
    }
    
    private func decodeAtomMeId(_ json: JsonElement) -> ProtoEventBundle? {
        guard let id = json["data"].string
        else {
            journal {"Received an empty me.id"}
            return nil
        }
        
        return ProtoEventBundle(
            type: .session(.me),
            id: nil,
            subject: MeTransactionSubject.meId(id: id)
        )
    }
    
    private func decodeAtomMeUrlPath(_ json: JsonElement) -> ProtoEventBundle? {
        guard let path = json["data"].string
        else {
            return nil
        }
        
        return ProtoEventBundle(
            type: .session(.me),
            id: nil,
            subject: MeTransactionSubject.meUrlPath(path: path)
        )
    }
    
    private func decodeAtomMeHistory(_ json: JsonElement) -> ProtoEventBundle? {
        return ProtoEventBundle(
            type: .session(.me),
            id: nil,
            subject: MeTransactionSubject.meHistory(
                lastMessageId: (json["data"].string?.jv_toInt() ?? json["data"].int)
            )
        )
    }
}

extension ProtoEventSubjectPayload {
    
    struct ConnectionConfig: IProtoEventSubjectPayloadModel {
        struct Body {
            let siteId: Int
            let chatserverHost: String
            let apiHost: String
            let filesHost: String
            let isLicensed: Bool?
            let rateConfig: JMTimelineRateConfig?
        }
        
        static let kindId = UUID()
        let status: RestResponseStatus
        let body: Body
    }
}
