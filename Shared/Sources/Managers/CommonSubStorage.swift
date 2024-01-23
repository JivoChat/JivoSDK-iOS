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
    func storeAgents(changes: [JVDatabaseModelChange], exclusive: Bool) -> [JVAgent]
    
    func updateAgent(change: JVDatabaseModelChange)
    func removeAgent(agentId: Int)
    func agents(withMe: Bool) -> [JVAgent]
    func agent(for agentID: Int, provideDefault: Bool) -> JVAgent?
    
    @discardableResult
    func storeDepartments(changes: [JVDatabaseModelChange], exclusive: Bool) -> [JVDepartment]
    
    @discardableResult
    func storeBots(changes: [JVDatabaseModelChange], exclusive: Bool) -> [JVBot]
    
    @discardableResult
    func storeTopics(changes: [JVDatabaseModelChange], exclusive: Bool) -> [JVTopic]
    
    func storeClients(changes: [JVDatabaseModelChange])
    func updateClient(change: JVDatabaseModelChange)
    func storeChat(change: JVDatabaseModelChange) -> JVChat?
    func updateChat(change: JVDatabaseModelChange)
    func clientWithID(_ clientID: Int, needsDefault: Bool) -> JVClient?
    func chatWithID(_ chatID: Int) -> JVChat?
    func chatsWithClientID(_ clientID: Int, evenArchived: Bool) -> [JVChat]
    func chatForMessage(_ message: JVMessage, evenArchived: Bool) -> JVChat?
    func topicWithID(_ topicID: Int) -> JVTopic?
    func unlink(chatId: Int)
    func unlink(chat: JVChat)
    func remove(chatID: Int, cleanup: Bool)
    func remove(chat: JVChat, cleanup: Bool)
    func storeMessage(change: JVDatabaseModelChange) -> JVMessage?
    func updateMessage(change: JVDatabaseModelChange) -> JVMessage?
    func messageWithID(_ messageID: Int) -> JVMessage?
    func messageWithUUID(_ messageUUID: String) -> JVMessage?
    func taskWithID(_ taskID: Int) -> JVTask?
    func updateChatTermination(chatID: Int, delay: Int)
}

class CommonSubStorage: BaseSubStorage {
    func storeAgents(changes: [JVDatabaseModelChange], exclusive: Bool) -> [JVAgent] {
        var agents = [JVAgent]()
        
        databaseDriver.readwrite { context in
            agents = context.upsert(of: JVAgent.self, with: changes)
            
            if exclusive {
                let keepAgentIDs = changes.map(\.primaryValue)
                let removalObjects = context.objects(JVAgent.self, options: nil).filter { agent in
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
            _ = context.update(of: JVAgent.self, with: change)
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
    
    func agents(withMe: Bool) -> [JVAgent] {
        return databaseDriver.agents(withMe: withMe)
    }
    
    func agent(for agentID: Int, provideDefault: Bool) -> JVAgent? {
        return databaseDriver.agent(for: agentID, provideDefault: provideDefault)
    }
    
    func storeDepartments(changes: [JVDatabaseModelChange], exclusive: Bool) -> [JVDepartment] {
        var departments = [JVDepartment]()
        
        databaseDriver.readwrite { context in
            departments = context.upsert(of: JVDepartment.self, with: changes)
            
            if exclusive {
                let keepDepartmentsIds = changes.map(\.primaryValue)
                let removalObjects = context.objects(JVDepartment.self, options: nil).filter { department in
                    guard !(keepDepartmentsIds.contains(department.ID)) else { return false }
                    return true
                }
                
                context.customRemove(objects: removalObjects, recursive: true)
            }
        }
        
        return departments
    }
    
    func storeBots(changes: [JVDatabaseModelChange], exclusive: Bool) -> [JVBot] {
        var bots = [JVBot]()
        
        databaseDriver.readwrite { context in
            bots = context.upsert(of: JVBot.self, with: changes)
            
            if exclusive {
                let keepBotsIds = changes.map(\.primaryValue)
                let removalObjects = context.objects(JVBot.self, options: nil).filter { bot in
                    guard !(keepBotsIds.contains(bot.id)) else { return false }
                    return true
                }
                
                context.customRemove(objects: removalObjects, recursive: true)
            }
        }
        
        return bots
    }
    
    func storeTopics(changes: [JVDatabaseModelChange], exclusive: Bool) -> [JVTopic] {
        var topics = [JVTopic]()
        
        databaseDriver.readwrite { context in
            topics = context.upsert(of: JVTopic.self, with: changes)
            
            if exclusive {
                let keepTopicsIds = changes.map(\.primaryValue)
                let removalObjects = context.objects(JVTopic.self, options: nil).filter { bot in
                    guard !(keepTopicsIds.contains(bot.id)) else { return false }
                    return true
                }
                
                context.customRemove(objects: removalObjects, recursive: true)
            }
        }

        return topics
    }

    func storeClients(changes: [JVDatabaseModelChange]) {
        _ = databaseDriver.upsert(of: JVClient.self, with: changes)
    }
    
    func updateClient(change: JVDatabaseModelChange) {
        _ = databaseDriver.update(of: JVClient.self, with: change)
    }
    
    func storeChat(change: JVDatabaseModelChange) -> JVChat? {
        return databaseDriver.upsert(of: JVChat.self, with: change)
    }
    
    func updateChat(change: JVDatabaseModelChange) {
        _ = databaseDriver.update(of: JVChat.self, with: change)
    }
    
    func clientWithID(_ clientID: Int, needsDefault: Bool) -> JVClient? {
        return databaseDriver.client(for: clientID, needsDefault: needsDefault)
    }
    
    func chatWithID(_ chatID: Int) -> JVChat? {
        return databaseDriver.chatWithID(chatID)
    }
    
    func chatsWithClientID(_ clientID: Int, evenArchived: Bool) -> [JVChat] {
        var chats = [JVChat]()
        
        databaseDriver.read { context in
            guard let client = context.client(for: clientID, needsDefault: false) else { return }
            chats = context.chatsWithClient(client, includeArchived: evenArchived)
        }
        
        return chats
    }
    
    func chatForMessage(_ message: JVMessage, evenArchived: Bool) -> JVChat? {
        return databaseDriver.chatForMessage(message, evenArchived: false)
    }
    
    func topicWithID(_ topicID: Int) -> JVTopic? {
        return databaseDriver.topic(for: topicID, needsDefault: false)
    }
    
    func unlink(chatId: Int) {
        databaseDriver.readwrite { context in
            guard let chat = context.chatWithID(chatId) else { return }
            context.unlinkChat(chat)
        }
    }

    func unlink(chat: JVChat) {
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
    
    func remove(chat: JVChat, cleanup: Bool) {
        guard chat.jv_isValid else { return }
        
        databaseDriver.readwrite { context in
            context.removeChat(chat, cleanup: cleanup)
        }
    }
    
    func storeMessage(change: JVDatabaseModelChange) -> JVMessage? {
        let message = databaseDriver.upsert(of: JVMessage.self, with: change)
        return message
    }
    
    func updateMessage(change: JVDatabaseModelChange) -> JVMessage? {
        return databaseDriver.update(of: JVMessage.self, with: change)
    }
    
    func messageWithID(_ messageID: Int) -> JVMessage? {
        let key = JVDatabaseModelCustomId(key: "m_id", value: messageID)
        return databaseDriver.object(JVMessage.self, customId: key)
    }
    
    func messageWithUUID(_ messageUUID: String) -> JVMessage? {
        let key = JVDatabaseModelCustomId(key: "m_uid", value: messageUUID)
        return databaseDriver.object(JVMessage.self, customId: key)
    }

    func taskWithID(_ taskID: Int) -> JVTask? {
        return databaseDriver.object(JVTask.self, primaryId: taskID)
    }
    
    func updateChatTermination(chatID: Int, delay: Int) {
        _ = databaseDriver.update(
            of: JVChat.self,
            with: JVChatTerminationChange(ID: chatID, delay: TimeInterval(delay)))
    }
}
