//
//  GraylogExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 23.12.2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation
import SwiftGraylog
import JMCodingKit

public typealias GraylogPayload = [String: String]
fileprivate var cachedAgentID: Int?
fileprivate var cachedRecentLivePacket = String()
fileprivate var cachedRecentRestRequest = String()
fileprivate var cachedRecentRestResponse = String()
fileprivate var cachedRecentPayload: GraylogPayload?

public extension Graylog {
    static func jv_linkTo(_ link: String) {
        guard let url = URL(string: link) else { return }
        setURL(url)
    }
    
    static func jv_setAgentID(_ agentID: Int?) {
        cachedAgentID = agentID
    }
    
    static func jv_setRecentLivePacket(_ packet: String) {
        cachedRecentLivePacket = packet
    }
    
    static func jv_setRecentRestRequest(_ request: String) {
        cachedRecentRestRequest = request
    }
    
    static func jv_setRecentRestResponse(_ response: String) {
        cachedRecentRestResponse = response
    }
    
    static func jv_buildPayload(brief: String, details: String?, file: String, line: Int, includeCaches: Bool) -> GraylogPayload {
        let values: [JsonElement?] = [
            JsonElement(key: "short_message", value: brief),
            JsonElement(key: "full_message", value: details),
            JsonElement(key: "_system_platform", value: "ios"),
            JsonElement(key: "_system_version", value: UIDevice.current.systemVersion),
            JsonElement(key: "_app_version", value: Bundle.main.jv_version),
            JsonElement(key: "_app_full_version", value: Bundle.main.jv_versionWithBuild),
            JsonElement(key: "_agent_id", value: cachedAgentID.flatMap { "\($0)" }),
            JsonElement(key: "_code_location", value: "\(URL(fileURLWithPath: file).lastPathComponent):\(line)"),
            includeCaches ? JsonElement(key: "_recent_live_packet", value: cachedRecentLivePacket) : nil,
            includeCaches ? JsonElement(key: "_recent_rest_request", value: cachedRecentRestRequest) : nil,
            includeCaches ? JsonElement(key: "_recent_rest_response", value: cachedRecentRestResponse) : nil
        ]
        
        var merged = JsonElement()
        values.jv_flatten().forEach { merged = merged.merged(with: $0) }
        return merged.ordictValue.compactMapValues({ $0.string }).unOrderedMap
    }
    
    static func jv_wrapRecentPayloadIntoException(exception: NSException) -> GraylogPayload {
        return cachedRecentPayload ?? jv_buildPayload(brief: "standalone-exception", details: nil, file: #file, line: #line, includeCaches: true)
    }
    
    static func jv_send(brief: String, details: String, file: String, line: Int, includeCaches: Bool) {
        cachedRecentPayload = jv_buildPayload(
            brief: brief,
            details: details,
            file: file,
            line: line,
            includeCaches: includeCaches)
        
        if let payload = cachedRecentPayload {
            Graylog.log(payload)
        }
    }
    
    static func jv_send(payload: GraylogPayload) {
        Graylog.log(payload)
    }
}
