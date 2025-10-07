//
//  JMTimelineMessageTaskItem.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import JMRepicKit
import JMTimelineKit

struct JMTimelineTaskInfo: JMTimelineInfo {
    let taskStatus: JVMessageBodyTaskStatus
    let taskID: Int
    let notificationEnabled: Bool
    let clientID: Int
    
    let notifyAt: Date?
    let createdAt: Date?
    let updatedAt: Date?
    
    let username: String?
    let userRepic: JMRepicItem?
    
    let taskName: String?
    
    let provider: JVChatTimelineProvider
    let interactor: JVChatTimelineInteractor
}

final class JMTimelineTaskItem: JMTimelinePayloadItem<JMTimelineTaskInfo> { }
