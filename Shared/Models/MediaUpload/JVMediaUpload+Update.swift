//
//  JVMediaUpload+Update.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

extension JVMediaUpload {
    func performApply(context: JVIDatabaseContext, environment: JVIDatabaseEnvironment, change: JVDatabaseModelChange) {
        defer {
            m_pk_str = m_id
        }
        
        if let c = change as? JVMediaUploadChange {
            if m_id == String() { m_id = c.ID }
            m_file_path = c.filePath ?? String()
            m_chat_id = c.chatID?.jv_toInt64 ?? 0
            m_recipient_type = c.recipientType
            m_recipient_id = c.recipientID.jv_toInt64
        }
    }
}

enum JVMediaUploadingPurpose: Equatable {
    case transfer(JVSenderData, chatID: Int)
    case avatar
    
    var chatID: Int? {
        switch self {
        case .transfer(_, let chatID): return chatID
        case .avatar: return nil
        }
    }
}

enum JVMediaUploadingResult {
    public struct Success {
        public let storage: String
        public let mime: String
        public let name: String
        public let key: String
        public let link: String
        public let dataSize: Int
        public let pixelSize: CGSize
        
        init(
            storage: String,
            mime: String,
            name: String,
            key: String,
            link: String,
            dataSize: Int,
            pixelSize: CGSize
        ) {
            self.storage = storage
            self.mime = mime
            self.name = name
            self.key = key
            self.link = link
            self.dataSize = dataSize
            self.pixelSize = pixelSize
        }
    }
    
    case success(Success)
    case cannotExtractData
    case sizeLimitExceeded
    case exportingFailed
    case unknownError
}

final class JVMediaUploadChange: JVDatabaseModelChange {
    public let ID: String
    public let chatID: Int?
    public let filePath: String?
    public let purpose: JVMediaUploadingPurpose
    public let width: Int
    public let height: Int
    public let sessionID: String
    public let completion: (JVMediaUploadingResult) -> Void
    
    init(ID: String,
                chatID: Int?,
                filePath: String?,
                purpose: JVMediaUploadingPurpose,
                width: Int,
                height: Int,
                sessionID: String,
                completion: @escaping (JVMediaUploadingResult) -> Void) {
        self.ID = ID
        self.chatID = chatID
        self.filePath = filePath
        self.purpose = purpose
        self.width = width
        self.height = height
        self.sessionID = sessionID
        self.completion = completion
        super.init()
    }
    
    required init(json: JsonElement) {
        abort()
    }
    
    func copy(filePath: String?) -> JVMediaUploadChange {
        return JVMediaUploadChange(
            ID: ID,
            chatID: chatID,
            filePath: filePath,
            purpose: purpose,
            width: width,
            height: height,
            sessionID: sessionID,
            completion: completion)
    }
    
    var recipientType: String {
        switch purpose {
        case .avatar: return "self"
        case .transfer(let target, _): return target.type.rawValue
        }
    }
    
    var recipientID: Int {
        switch purpose {
        case .avatar: return 0
        case .transfer(let target, _): return target.ID
        }
    }
}
