//
//  SdkClientProto.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 05.10.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import JMCodingKit

protocol ISdkClientProto: IProto {
    func registerDevice(deviceId: String, deviceLiveToken: String, siteId: Int, channelId: String, clientId: String)
    func setContactInfo(clientId: String, name: String?, email: String?, phone: String?, brief: String?)
    func setCustomData(fields: [JVSessionCustomDataField])
}

final class SdkClientProto: BaseProto, ISdkClientProto {
    func registerDevice(deviceId: String, deviceLiveToken: String, siteId: Int, channelId: String, clientId: String) {
        let options = RestRequestOptions(
            behavior: .ephemeral(priority: 1.0),
            method: .post,
            headers: [
                "Content-Type": "application/json",
                "x-jv-client-id": clientId
            ],
            query: Array(),
            body: .json(.params([
                JsonElement(key: "device_id", value: deviceId),
                JsonElement(key: "platform", value: "ios"),
                JsonElement(key: "token", value: deviceLiveToken)
            ]))
        )
        
//        print("[DEBUG] (Un)subscribe: \(options.body)")
        
        let contextID = networking.flushContext()
        _ = networking.send(
            output: .rest(
                kindID: ProtoEventSubjectPayload.PushRegistration.kindID,
                target: .build(scope: .chatServer, path: "/client/\(siteId)/\(channelId)/device"),
                options: options,
                contextID: contextID
            ),
            caching: .auto)
    }
    
    func setContactInfo(clientId: String, name: String?, email: String?, phone: String?, brief: String?) {
        let mapping = [
            "name": name,
            "email": email,
            "phone": phone,
            "desc": brief
        ]
        
        for (key, value) in mapping {
            guard let value = value?.jv_trimmed().jv_valuable
            else {
                continue
            }
            
            _ = networking.send(
                output: .atom(
                    type: "atom/user.\(key)",
                    context: nil,
                    id: clientId,
                    data: value
                ),
                caching: .auto)
        }
    }
    
    func setCustomData(fields: [JVSessionCustomDataField]) {
        let array = fields.map { field -> [String: String] in
            var dict = [String: String]()
            dict["title"] = field.title
            dict["key"] = field.key
            dict["content"] = field.content
            dict["link"] = field.link
            return dict
        }
        
        guard let payload = try? JSONEncoder().encode(array)
        else {
            return
        }
        
        _ = networking.send(
            output: .atom(
                type: "atom/user.custom-data",
                context: nil,
                id: nil,
                data: String(data: payload, encoding: .utf8)
            ),
            caching: .auto)
    }
    
    override func decodeToSubject(event: NetworkingSubject) -> IProtoEventSubject? {
        switch event {
        case let .rest(.response(ProtoEventSubjectPayload.PushRegistration.kindID, _, response)):
            return decodePushRegistration(response)
        default:
            return super.decodeToSubject(event: event)
        }
    }
    
    private func decodePushRegistration(_ response: NetworkingSubRestEvent.Response) -> SessionProtoEventSubject? {
        let meta = ProtoEventSubjectPayload.PushRegistration(
            status: response.status,
            body: .init()
        )
        
        return .pushRegistration(meta)
    }
}

extension ProtoEventSubjectPayload {
    struct PushRegistration: IProtoEventSubjectPayloadModel {
        struct Body {
        }
        
        static let kindID = UUID()
        let status: RestResponseStatus
        let body: Body
    }
}
