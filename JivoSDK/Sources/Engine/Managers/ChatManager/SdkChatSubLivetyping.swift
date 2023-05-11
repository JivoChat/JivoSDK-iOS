//
//  SdkChatSubLivetyping.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04.08.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation

struct TypingStatusData {
    let clientHash: Int
    let lastTypingTime: Date
}

protocol ISdkChatSubLivetyping: AnyObject {
    func sendTyping(clientHash: Int, text: String)
}

final class SdkChatSubLivetyping: ISdkChatSubLivetyping {
    private let proto: ISdkChatProto
    private let timeoutBoxService: ISchedulingDriver

    private var clientTypingData: TypingStatusData?
    
    init(proto: ISdkChatProto, timeoutBoxService: ISchedulingDriver) {
        self.proto = proto
        self.timeoutBoxService = timeoutBoxService
    }
    
    func sendTyping(clientHash: Int, text: String) {
        let typingData = TypingStatusData(
            clientHash: clientHash,
            lastTypingTime: Date()
        )
        
        if let lastData = clientTypingData, typingData.clientHash != lastData.clientHash {
            sendPacket(data: lastData, text: String())
        }
        
        let timeoutBoxID = SchedulingActionID.meTyping(ID: clientHash)
        if !timeoutBoxService.hasScheduled(for: timeoutBoxID) {
            sendPacket(data: typingData, text: text)
            
            timeoutBoxService.schedule(
                for: timeoutBoxID,
                delay: 5,
                repeats: true,
                block: { [unowned self] in
                    guard let lastData = self.clientTypingData else { return }
                    if Date().timeIntervalSince(lastData.lastTypingTime) > 3 {
                        self.sendPacket(data: typingData, text: String())
                        _ = self.timeoutBoxService.kill(for: timeoutBoxID)
                    }
                    else {
                        self.sendPacket(data: typingData, text: text)
                    }
                }
            )
        }
        
        clientTypingData = typingData
    }
    
    private func sendPacket(data: TypingStatusData, text: String) {
        proto
            .sendTyping(text: text)
    }
}
