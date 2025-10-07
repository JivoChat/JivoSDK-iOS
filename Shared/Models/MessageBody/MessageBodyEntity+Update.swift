//
//  MessageBodyEntity+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension MessageBodyEntity {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        if let c = change as? JVMessageBodyGeneralChange {
            m_agent = c.agentID.flatMap { $0 > 0 ? context.agent(for: $0, provideDefault: true) : nil }
            m_department = c.departmentID.flatMap { $0 > 0 ? context.department(for: $0) : nil }
            m_to = c.to
            m_from = c.from
            m_subject = c.subject
            m_text = c.text
            m_event = c.event
            m_phone = c.phone
            m_email = c.email
            m_end_call_side = c.endCallSide
            m_call_id = c.callID
            m_type = c.type
            m_reason = c.reason
            m_record_link = c.recordLink
            m_task_id = c.taskID?.jv_toInt64(.standard) ?? 0
            m_created_at = c.createdTs.flatMap { Date(timeIntervalSince1970: $0) }
            m_is_important = c.isImportant ?? false
            m_updated_at = c.updatedTs.flatMap { Date(timeIntervalSince1970: $0) }
            m_transitioned_at = c.transitionTs.flatMap { Date(timeIntervalSince1970: $0) }
            m_notify_at = c.notifyTs.flatMap { Date(timeIntervalSince1970: $0) }
            m_status = c.status
            m_task_status = c.taskStatus
            m_buttons = c.buttons
            m_order_id = c.orderID
        }
    }
}

final class JVMessageBodyGeneralChange: JVDatabaseModelChange {
    public let agentID: Int?
    public let to: String?
    public let from: String?
    public let subject: String?
    public let text: String?
    public let event: String?
    public let phone: String?
    public let email: String?
    public let endCallSide: String?
    public let callID: String?
    public let type: String?
    public let reason: String?
    public let recordLink: String?
    public let taskID: Int?
    public let isImportant: Bool?
    public let createdTs: TimeInterval?
    public let updatedTs: TimeInterval?
    public let transitionTs: TimeInterval?
    public let notifyTs: TimeInterval?
    public let status: String?
    public let taskStatus: String?
    public let buttons: String?
    public let orderID: String?
    public let departmentID: Int?

    required init(json: JsonElement) {
        let call = json.has(key: "call") ?? json
        let task = json.has(key: "reminder") ?? json

        let callAgentID = call["agent_id"].int
        event = call["status"].string
        phone = (call["phone"].string ?? json["client_phone"].string)?.jv_valuable.flatMap { "+" + $0 }
        email = call["email"].string ?? json["client_email"].string
        endCallSide = call["end_call_side"].string
        callID = call["call_id"].string
        type = call["type"].string
        reason = call["reason"].string
        recordLink = call["record_url"].string

        to = json["to"].string
        from = json["from"].string
        subject = json["subject"].string

        let taskAgentID = task["agent_id"].int
        let taskText = task["text"].string
        taskID = task["reminder_id"].int
        isImportant = task["is_important"].boolValue
        createdTs = task["created_ts"].double
        updatedTs = task["updated_ts"].double
        transitionTs = task["transition_ts"].double
        notifyTs = task["notify_ts"].double
        status = json["status"].string
        taskStatus = task["status"].string

        let defaultAgentID = json["agent"].int ?? json["by_agent"].int
        agentID = callAgentID ?? taskAgentID ?? defaultAgentID
        departmentID = json["group"].int

        let defaultText = json["text"].string
        text = taskText ?? defaultText
        
        if let keyboard = json["keyboard"].array?.compactMap({ $0["text"].string }) {
            buttons = keyboard.isEmpty ? nil : keyboard.joined(separator: "\n")
        }
        else {
            buttons = nil
        }
        
        orderID = json["order_id"].string

        super.init(json: json)
    }
    
    var isValidCall: Bool {
        guard let _ = callID else { return false }
        guard let _ = type else { return false }
        return true
    }
}
