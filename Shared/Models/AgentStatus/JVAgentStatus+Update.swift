//
//  JVAgentStatus+Update.swift
//  App
//
//  Created by Stan Potemkin on 24.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import AVFoundation
import JMCodingKit

extension JVAgentStatus {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_num = Int64(m_id)
        }
        
        if let c = change as? JVAgentStatusGeneralChange {
            m_id = Int16(c.statusID)
            m_title = c.title
            m_emoji = c.emoji
            m_position = (c.position > 0 ? Int16(c.position) : m_position)
        }
    }
}

public final class JVAgentStatusGeneralChange: JVDatabaseModelChange, Codable {
    public let statusID: Int
    public let title: String
    public let emoji: String
    public let position: Int
    
    public override var primaryValue: Int {
        return statusID
    }
    
    public override var isValid: Bool {
        return (statusID > 0)
    }
    
    required public init(json: JsonElement) {
        statusID = json["agent_status_id"].intValue
        title = json["title"].stringValue
        position = json["position"].intValue
        emoji = json["emoji"].stringValue
        super.init(json: json)
    }
}

public struct JVAgentTechConfig: Codable {
    public var priceListId: Int? = nil
    public var guestInsightEnabled: Bool = true
    public var fileSizeLimit: Int = 10
    public var disableArchiveForRegular: Bool = false
    public var iosTelephonyEnabled: Bool? = nil
    public var limitedCRM: Bool = true
    public var assignedAgentEnabled: Bool = true
    public var messageEditingEnabled: Bool = true
    public var groupsEnabled: Bool = true
    public var mentionsEnabled: Bool = true
    public var commentsEnabled: Bool = true
    public var reactionsEnabled: Bool = true
    public var businessChatEnabled: Bool = true
    public var billingUpdateEnabled: Bool = true
    public var standaloneTasks: Bool = true
    public var feedbackSdkEnabled: Bool = true
    public var mediaServiceEnabled: Bool = true
    public var voiceMessagesEnabled: Bool = false
    
    public init() {
    }
    
    public init(
        priceListId: Int?,
        guestInsightEnabled: Bool,
        fileSizeLimit: Int,
        disableArchiveForRegular: Bool,
        iosTelephonyEnabled: Bool?,
        limitedCRM: Bool,
        assignedAgentEnabled: Bool,
        messageEditingEnabled: Bool,
        groupsEnabled: Bool,
        mentionsEnabled: Bool,
        commentsEnabled: Bool,
        reactionsEnabled: Bool,
        businessChatEnabled: Bool,
        billingUpdateEnabled: Bool,
        standaloneTasks: Bool,
        feedbackSdkEnabled: Bool,
        mediaServiceEnabled: Bool,
        voiceMessagesEnabled: Bool
    ) {
        self.priceListId = priceListId
        self.guestInsightEnabled = guestInsightEnabled
        self.fileSizeLimit = fileSizeLimit
        self.disableArchiveForRegular = disableArchiveForRegular
        self.iosTelephonyEnabled = iosTelephonyEnabled
        self.limitedCRM = limitedCRM
        self.assignedAgentEnabled = assignedAgentEnabled
        self.messageEditingEnabled = messageEditingEnabled
        self.groupsEnabled = groupsEnabled
        self.mentionsEnabled = mentionsEnabled
        self.commentsEnabled = commentsEnabled
        self.reactionsEnabled = reactionsEnabled
        self.businessChatEnabled = businessChatEnabled
        self.billingUpdateEnabled = billingUpdateEnabled
        self.standaloneTasks = standaloneTasks
        self.feedbackSdkEnabled = feedbackSdkEnabled
        self.mediaServiceEnabled = mediaServiceEnabled
        self.voiceMessagesEnabled = voiceMessagesEnabled
    }
    
    public var canReceiveCalls: Bool? {
        guard let enabled = iosTelephonyEnabled else { return nil }
        guard AVAudioSession.sharedInstance().recordPermission != .denied else { return false }
        return enabled
    }
}

public enum JVAgentLicensedFeature: Int {
    case blacklist
    case geoip
    case phrases
    case transfer
    case invite
    case away
    case typing
    case info
    case files
    case guests
    
    public func resolveBit(within raw: Int) -> Bool {
        return (raw & (1 << rawValue)) > 0
    }
}

public final class JVAgentSessionGeneralChange: JVDatabaseModelChange, Codable {
    public var sessionID: String
    public var email: String
    public var siteID: Int
    public var isAdmin: Bool
    public var isOperator: Bool
    public var voxLogin: String
    public var voxPassword: String
    public var mobileCalls: Bool
    public var workingState: Bool
    
    public override var primaryValue: Int {
        return siteID
    }
    
    public override var isValid: Bool {
        guard let _ = sessionID.jv_valuable else { return false }
        return true
    }
    
    required public init(json: JsonElement) {
        sessionID = json["agent_info"]["agent_session_id"].string ?? json["jv_sess_id"].stringValue
        email = json["agent_info"]["email"].stringValue
        isAdmin = json["agent_info"]["is_admin"].boolValue
        isOperator = json["agent_info"]["is_operator"].bool ?? true
        siteID = json["agent_info"]["site_id"].intValue
        voxLogin = json["agent_info"]["vox_name"].stringValue
        voxPassword = json["agent_info"]["vox_password"].stringValue
        mobileCalls = json["agent_info"]["calls_mobile"].boolValue
        workingState = ((json["agent_info"]["work_state"].int ?? 1) > 0)
        super.init(json: json)
    }
}

public final class JVAgentSessionContextChange: JVDatabaseModelChange {
    public let scanned: Bool
    public let widgetPublicID: String?
    public let agentsJSON: JsonElement?
    public let agents: [JVAgentGeneralChange]?
    public let clients: [JVClientGeneralChange]?
    public let techConfig: JVAgentTechConfig?
    public let currency: String?
    public let pricelistID: Int?
    public let licenseLimit: Int?

    public override var isValid: Bool {
        return scanned
    }
    
    required public init(json: JsonElement) {
        if let context = json.has(key: "rmo_context") {
            scanned = true
            
            widgetPublicID = context["sites"].arrayValue.first?["public_id"].string
            agentsJSON = context.has(key: "agents")
            
            agents = agentsJSON?.parseList()
            clients = context["clients"].parseList()
            
            if let misc = context.has(key: "misc") {
                techConfig = JVAgentTechConfig(
                    priceListId: misc["pricelist_id"].int,
                    guestInsightEnabled: ((misc["disable_visitors_insight"].int ?? 0) == 0),
                    fileSizeLimit: misc["max_file_size"].int ?? 10,
                    disableArchiveForRegular: ((misc["disable_archive_non_admins"].int ?? 0) > 0),
                    iosTelephonyEnabled: ((misc["enable_ios_telephony"].int ?? 1) > 0),
                    limitedCRM: ((misc["enable_crm"].int ?? 1) > 0),
                    assignedAgentEnabled: ((misc["enable_assigned_agent"].int ?? 1) > 0),
                    messageEditingEnabled: ((misc["enable_message_edit"].int ?? 1) > 0),
                    groupsEnabled: ((misc["enable_team_chats"].int ?? 1) > 0),
                    mentionsEnabled: ((misc["enable_mentions"].int ?? 1) > 0),
                    commentsEnabled: ((misc["enable_comments"].int ?? 1) > 0),
                    reactionsEnabled: ((misc["enable_reactions"].int ?? 1) > 0),
                    businessChatEnabled: ((misc["enable_imessage"].int ?? 1) > 0),
                    billingUpdateEnabled: ((misc["enable_new_billing"].int ?? 0) > 0 && ((context["is_operator_model_enabled"].bool ?? true) == true)),
                    standaloneTasks: ((misc["enable_reminder_without_open_chat"].int ?? 1) > 0),
                    feedbackSdkEnabled: ((misc["enable_feedback_sdk"].int ?? 1) > 0 && (misc["disable_feedback_sdk_ios"].int ?? 0) < 1),
                    mediaServiceEnabled: ((misc["enable_media_service_uploading"].int ?? 1) > 0 && (misc["disable_media_service_uploading"].int ?? 0) < 1),
                    voiceMessagesEnabled: (misc["enable_voice_messages"].int ?? 0) > 0
                )
                
                currency = misc["currency"].string
                pricelistID = misc["pricelist_id"].int
                licenseLimit = misc["license_limit"].int
            }
            else {
                techConfig = nil
                currency = nil
                pricelistID = nil
                licenseLimit = nil
            }
        }
        else {
            scanned = false
            widgetPublicID = nil
            agentsJSON = JsonElement()
            agents = []
            clients = []
            techConfig = nil
            currency = nil
            pricelistID = nil
            licenseLimit = nil
        }
        
        super.init(json: json)
    }
}

public final class JVAgentSessionBoxesChange: JVDatabaseModelChange {
    public let source: JsonElement
    public let chats: [JVChatGeneralChange]
    
    required public init(json: JsonElement) {
        source = json
        chats = json["chats"].parseList() ?? []
        super.init(json: json)
    }
    
    public init(source: JsonElement, chats: [JVChatGeneralChange]) {
        self.source = source
        self.chats = chats
        super.init()
    }

    public var clientChats: [JVChatGeneralChange] {
        return chats.filter { $0.client != nil }
    }

    public var teamChats: [JVChatGeneralChange] {
        return chats.filter { !($0.isGroup == true) && $0.client == nil }
    }
    
    public var groupChats: [JVChatGeneralChange] {
        return chats.filter { ($0.isGroup == true) }
    }
    
    public var chatIDs: [Int] {
        return chats.map { $0.ID }
    }
    
    public func cachable() -> JVAgentSessionBoxesChange {
        return JVAgentSessionBoxesChange(
            source: source,
            chats: chats.map { $0.cachable() }
        )
    }
}

public final class JVAgentSessionActivityChange: JVDatabaseModelChange {
    public let isActive: Bool
        public init(isActive: Bool) {
        self.isActive = isActive
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

public final class JVAgentSessionMobileCallsChange: JVDatabaseModelChange {
    public let enabled: Bool
    
    public init(enabled: Bool) {
        self.enabled = enabled
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError("init(json:) has not been implemented")
    }
}

public final class JVAgentSessionWorktimeChange: JVDatabaseModelChange {
    public let agentID: Int?
    public let isWorking: Bool?
    public let isWorkingHidden: Bool
    
    public init(isWorking: Bool?, isWorkingHidden: Bool) {
        self.agentID = nil
        self.isWorking = isWorking
        self.isWorkingHidden = isWorkingHidden
        super.init()
    }
    
    required public init(json: JsonElement) {
        agentID = json["agent_id"].int
        isWorking = json["work_state"].int.flatMap { $0 > 0 }
        isWorkingHidden = false
        super.init(json: json)
    }
}

public final class JVAgentSessionChannelsChange: JVDatabaseModelChange {
    public let channels: [JVChannelGeneralChange]
    
    public init(channels: [JVChannelGeneralChange]) {
        self.channels = channels
        super.init()
    }
    
    required public init(json: JsonElement) {
        channels = []
        super.init(json: json)
    }
}

public final class JVAgentSessionChannelUpdateChange: JVDatabaseModelChange {
    public let channel: JVChannelGeneralChange
    
    public init(channel: JVChannelGeneralChange) {
        self.channel = channel
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError()
    }
}

public final class JVAgentSessionChannelRemoveChange: JVDatabaseModelChange {
    public let channelId: Int
    
    public init(channelId: Int) {
        self.channelId = channelId
        super.init()
    }
    
    required public init(json: JsonElement) {
        fatalError()
    }
}

public func JVAgentSessionParseFeatures(source: JsonElement) -> Int {
    func _bit(key: String, flag: JVAgentLicensedFeature) -> Int {
        let value = source[key].boolValue ? 1 : 0
        return (value << flag.rawValue)
    }
    
    let flags: [Int] = [
        _bit(key: "blacklist", flag: .blacklist),
        _bit(key: "geoip", flag: .geoip),
        _bit(key: "canned", flag: .phrases),
        _bit(key: "redirect", flag: .transfer),
        _bit(key: "multiagents", flag: .invite),
        _bit(key: "away", flag: .away),
        _bit(key: "typing_insight", flag: .typing),
        _bit(key: "page_info", flag: .info),
        _bit(key: "file_transfer", flag: .files),
        _bit(key: "visitors_insight", flag: .guests)
    ]
    
    return flags.reduce(0, +)
}
