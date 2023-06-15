//
//  NetworkingSubApns.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 03.08.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

final class NetworkingSubApns: INetworkingSubApns {
    private let driver: IApnsConnectionDriver
    
    init(driver: IApnsConnectionDriver, targetDetector: @escaping ([String: Any]) -> NetworkingSubApnsEvent.Target) {
        self.driver = driver
        
        driver.messageHandler = { [unowned self] json, applicationState, date in
            journal {"{network-sub-apns} ::init(message-handler) app @json[\(json)]"}
            
            let target = targetDetector(json.dictObject)
            let messageType = json["message_type"].stringValue
            let messageDate = json["created_ts"].int.flatMap { Date(timeIntervalSince1970: TimeInterval($0)) }
            
            let event = NetworkingSubApnsEvent.payload(target, messageType, messageDate ?? date, applicationState, json)
            self.eventObservable.broadcast(event)
        }
    }
    
    let eventObservable = JVBroadcastTool<NetworkingSubApnsEvent>()
}

/**
 message_type: 'work_time_start|work_time_end|work_time_expiring',
 site_id: int,
 agent_id: int,
 push_id: string,
 next_update_ts: <UTC unix timestamp>
 */
