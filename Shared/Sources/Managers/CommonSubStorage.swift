//
//  CommonStorage.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 16.08.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation


protocol ICommonSubStorage: IBaseSubStorage {
    @discardableResult
    func storeAgents(changes: [JVDatabaseModelChange], exclusive: Bool) -> [AgentEntity]
    
    func updateAgent(change: JVDatabaseModelChange)
    func removeAgent(agentId: Int)
    func agents(withMe: Bool) -> [AgentEntity]
    func agent(for agentID: Int, provideDefault: Bool) -> AgentEntity?
    
    @discardableResult
    func storeDepartments(changes: [JVDatabaseModelChange], exclusive: Bool) -> [DepartmentEntity]
    
    @discardableResult
    func storeBots(changes: [JVDatabaseModelChange], exclusive: Bool) -> [BotEntity]
    
    @discardableResult
    func storeTopics(changes: [JVDatabaseModelChange], exclusive: Bool) -> [TopicEntity]
    
    func storeClients(changes: [JVDatabaseModelChange])
    func updateClient(change: JVDatabaseModelChange)
    func storeChat(change: JVDatabaseModelChange) -> ChatEntity?
    func updateChat(change: JVDatabaseModelChange)
    func clientWithID(_ clientID: Int, needsDefault: Bool) -> ClientEntity?
    func chatWithID(_ chatID: Int) -> ChatEntity?
    func chatsWithClientID(_ clientID: Int, evenArchived: Bool) -> [ChatEntity]
    func chatForMessage(_ message: MessageEntity, evenArchived: Bool) -> ChatEntity?
    func topicWithID(_ topicID: Int) -> TopicEntity?
    func unlink(chatId: Int)
    func unlink(chat: ChatEntity)
    func remove(chatID: Int, cleanup: Bool)
    func remove(chat: ChatEntity, cleanup: Bool)
    func storeMessage(change: JVDatabaseModelChange) -> MessageEntity?
    func updateMessage(change: JVDatabaseModelChange) -> MessageEntity?
    func messageWithID(_ messageID: Int) -> MessageEntity?
    func messageWithUUID(_ messageUUID: String) -> MessageEntity?
    func taskWithID(_ taskID: Int) -> TaskEntity?
    func updateChatTermination(chatID: Int, delay: Int)
}

class CommonSubStorage: BaseSubStorage {
    func storeAgents(changes: [JVDatabaseModelChange], exclusive: Bool) -> [AgentEntity] {
        var agents = [AgentEntity]()
        
        databaseDriver.readwrite { context in
            agents = context.upsert(of: AgentEntity.self, with: changes)
            
            if exclusive {
                let keepAgentIDs = changes.map(\.primaryValue)
                let removalObjects = context.objects(AgentEntity.self, options: nil).filter { agent in
                    guard !(agent.isMe) else { return false }
                    guard !(keepAgentIDs.contains(agent.ID)) else { return false }
                    return true
                }
                
                context.customRemove(objects: removalObjects, recursive: true)
            }
        }
        
        return agents
    }
    
    func updateAgent(change: JVDatabaseModelChange) {
        databaseDriver.readwrite { context in
            _ = context.update(of: AgentEntity.self, with: change)
        }
    }
    
    func removeAgent(agentId: Int) {
        databaseDriver.readwrite { context in
            guard let agent = context.agent(for: agentId, provideDefault: false)
            else {
                return
            }
            
            context.customRemove(objects: [agent], recursive: true)
        }
    }
    
    func agents(withMe: Bool) -> [AgentEntity] {
        return databaseDriver.agents(withMe: withMe)
    }
    
    func agent(for agentID: Int, provideDefault: Bool) -> AgentEntity? {
        return databaseDriver.agent(for: agentID, provideDefault: provideDefault)
    }
    
    func storeDepartments(changes: [JVDatabaseModelChange], exclusive: Bool) -> [DepartmentEntity] {
        var departments = [DepartmentEntity]()
        
        databaseDriver.readwrite { context in
            departments = context.upsert(of: DepartmentEntity.self, with: changes)
            
            if exclusive {
                let keepDepartmentsIds = changes.map(\.primaryValue)
                let removalObjects = context.objects(DepartmentEntity.self, options: nil).filter { department in
                    guard !(keepDepartmentsIds.contains(department.ID)) else { return false }
                    return true
                }
                
                context.customRemove(objects: removalObjects, recursive: true)
            }
        }
        
        return departments
    }
    
    func storeBots(changes: [JVDatabaseModelChange], exclusive: Bool) -> [BotEntity] {
        var bots = [BotEntity]()
        
        databaseDriver.readwrite { context in
            bots = context.upsert(of: BotEntity.self, with: changes)
            
            if exclusive {
                let keepBotsIds = changes.map(\.primaryValue)
                let removalObjects = context.objects(BotEntity.self, options: nil).filter { bot in
                    guard !(keepBotsIds.contains(bot.id)) else { return false }
                    return true
                }
                
                context.customRemove(objects: removalObjects, recursive: true)
            }
        }
        
        return bots
    }
    
    func storeTopics(changes: [JVDatabaseModelChange], exclusive: Bool) -> [TopicEntity] {
        var topics = [TopicEntity]()
        
        databaseDriver.readwrite { context in
            topics = context.upsert(of: TopicEntity.self, with: changes)
            
            if exclusive {
                let keepTopicsIds = changes.map(\.primaryValue)
                let removalObjects = context.objects(TopicEntity.self, options: nil).filter { bot in
                    guard !(keepTopicsIds.contains(bot.id)) else { return false }
                    return true
                }
                
                context.customRemove(objects: removalObjects, recursive: true)
            }
        }

        return topics
    }

    func storeClients(changes: [JVDatabaseModelChange]) {
        _ = databaseDriver.upsert(of: ClientEntity.self, with: changes)
    }
    
    func updateClient(change: JVDatabaseModelChange) {
        _ = databaseDriver.update(of: ClientEntity.self, with: change)
    }
    
    func storeChat(change: JVDatabaseModelChange) -> ChatEntity? {
        return databaseDriver.upsert(of: ChatEntity.self, with: change)
    }
    
    func updateChat(change: JVDatabaseModelChange) {
        _ = databaseDriver.update(of: ChatEntity.self, with: change)
    }
    
    func clientWithID(_ clientID: Int, needsDefault: Bool) -> ClientEntity? {
        return databaseDriver.client(for: clientID, needsDefault: needsDefault)
    }
    
    func chatWithID(_ chatID: Int) -> ChatEntity? {
        return databaseDriver.chatWithID(chatID)
    }
    
    func chatsWithClientID(_ clientID: Int, evenArchived: Bool) -> [ChatEntity] {
        var chats = [ChatEntity]()
        
        databaseDriver.read { context in
            guard let client = context.client(for: clientID, needsDefault: false) else { return }
            chats = context.chatsWithClient(client, includeArchived: evenArchived)
        }
        
        return chats
    }
    
    func chatForMessage(_ message: MessageEntity, evenArchived: Bool) -> ChatEntity? {
        return databaseDriver.chatForMessage(message, evenArchived: false)
    }
    
    func topicWithID(_ topicID: Int) -> TopicEntity? {
        return databaseDriver.topic(for: topicID, needsDefault: false)
    }
    
    func unlink(chatId: Int) {
        databaseDriver.readwrite { context in
            guard let chat = context.chatWithID(chatId) else { return }
            context.unlinkChat(chat)
        }
    }

    func unlink(chat: ChatEntity) {
        guard chat.jv_isValid else { return }
        
        databaseDriver.readwrite { context in
            context.unlinkChat(chat)
        }
    }
    
    func remove(chatID: Int, cleanup: Bool) {
        databaseDriver.readwrite { context in
            guard let chat = context.chatWithID(chatID) else { return }
            context.removeChat(chat, cleanup: cleanup)
        }
    }
    
    func remove(chat: ChatEntity, cleanup: Bool) {
        guard chat.jv_isValid else { return }
        
        databaseDriver.readwrite { context in
            context.removeChat(chat, cleanup: cleanup)
        }
    }
    
    func storeMessage(change: JVDatabaseModelChange) -> MessageEntity? {
        let message = databaseDriver.upsert(of: MessageEntity.self, with: change)
        return message
    }
    
    func updateMessage(change: JVDatabaseModelChange) -> MessageEntity? {
        return databaseDriver.update(of: MessageEntity.self, with: change)
    }
    
    func messageWithID(_ messageID: Int) -> MessageEntity? {
        let key = JVDatabaseModelCustomId(key: "m_id", value: messageID)
        return databaseDriver.object(MessageEntity.self, customId: key)
    }
    
    func messageWithUUID(_ messageUUID: String) -> MessageEntity? {
        let key = JVDatabaseModelCustomId(key: "m_uid", value: messageUUID)
        return databaseDriver.object(MessageEntity.self, customId: key)
    }

    func taskWithID(_ taskID: Int) -> TaskEntity? {
        return databaseDriver.object(TaskEntity.self, primaryId: taskID)
    }
    
    func updateChatTermination(chatID: Int, delay: Int) {
        _ = databaseDriver.update(
            of: ChatEntity.self,
            with: JVChatTerminationChange(ID: chatID, delay: TimeInterval(delay)))
    }
}
