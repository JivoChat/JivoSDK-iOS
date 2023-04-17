//
//  DatabaseDriver+Extensions.swift
//  App
//
//  Created by Stan Potemkin on 30.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import CoreData

public extension JVIDatabaseDriver {
    func insert<OT: JVDatabaseModel>(of type: OT.Type, with changes: [JVDatabaseModelChange]?) -> [OT] {
        var result = [OT]()
        
        readwrite { context in
            result = context.insert(of: type, with: changes)
        }
        
        return result
    }
    
    func upsert<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange) -> OT? {
        var result: OT?
        
        readwrite { context in
            result = context.upsert(of: type, with: change)
        }

        return result
    }
    
    func upsert<OT: JVDatabaseModel>(of type: OT.Type, with changes: [JVDatabaseModelChange]) -> [OT] {
        var result = [OT]()
        
        readwrite { context in
            result = context.upsert(of: type, with: changes)
        }
        
        return result
    }
    
    func update<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange) -> OT? {
        var result: OT?
        
        readwrite { context in
            result = context.update(of: type, with: change)
        }
        
        return result
    }
    
    func replaceAll<OT: JVDatabaseModel>(of type: OT.Type, with changes: [JVDatabaseModelChange]) -> [OT] {
        var result = [OT]()
        
        readwrite { context in
            result = context.replaceAll(of: type, with: changes)
        }
        
        return result
    }
    
    func chatWithID(_ ID: Int) -> JVChat? {
        var chat: JVChat?
        
        read { context in
            chat = context.chatWithID(ID)
        }
        
        return chat
    }

    func client(for clientID: Int, needsDefault: Bool) -> JVClient? {
        var client: JVClient?

        read { context in
            client = context.client(for: clientID, needsDefault: false)
        }
        
        if client == nil, needsDefault {
            readwrite { context in
                client = context.client(for: clientID, needsDefault: true)
            }
        }

        return client
    }
    
    func chatForMessage(_ message: JVMessage, evenArchived: Bool) -> JVChat? {
        if let client = message.client {
            return chat(for: client.ID, evenArchived: evenArchived)
        }
        else {
            return chatWithID(message.chatID)
        }
    }

    func agents(withMe: Bool) -> [JVAgent] {
        var agents = [JVAgent]()
        
        let predicate: NSPredicate
        if withMe {
            predicate = NSPredicate(format: "m_email != ''")
        }
        else {
            predicate = NSPredicate(format: "m_email != '' AND m_session == nil")
        }
        
        read { context in
            agents = context.objects(
                JVAgent.self,
                options: JVDatabaseRequestOptions(
                    filter: predicate
                )
            )
        }
        
        return agents
    }
    
    func agent(for agentID: Int, provideDefault: Bool) -> JVAgent? {
        var agent: JVAgent?
        
        read { context in
            agent = context.agent(for: agentID, provideDefault: false)
        }
        
        if agent == nil, provideDefault {
            readwrite { context in
                agent = context.agent(for: agentID, provideDefault: true)
            }
        }
        
        return agent
    }
    
    func bot(for botID: Int, provideDefault: Bool) -> JVBot? {
        var bot: JVBot?
        
        read { context in
            bot = context.bot(for: botID, provideDefault: false)
        }
        
        if bot == nil, provideDefault {
            readwrite { context in
                bot = context.bot(for: botID, provideDefault: true)
            }
        }
        
        return bot
    }
    
    func chat(for clientID: Int, evenArchived: Bool) -> JVChat? {
        var chat: JVChat?
        
        read { context in
            guard let client = context.client(for: clientID, needsDefault: false) else { return }
            chat = context.chatsWithClient(client, includeArchived: evenArchived).first
        }
        
        return chat
    }
    
    func message(for UUID: String) -> JVMessage? {
        var message: JVMessage?
        
        read { context in
            message = context.messageWithUUID(UUID)
        }
        
        return message
    }
}

public extension JVIDatabaseContext {
    func find<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?) -> OT? {
        if let change = change, change.isValid {
            if let integerKey = change.integerKey {
                let customId = JVDatabaseModelCustomId(key: integerKey.key, value: integerKey.value)
                return object(OT.self, customId: customId)
            }
            else if let stringKey = change.stringKey {
                let customId = JVDatabaseModelCustomId(key: stringKey.key, value: stringKey.value)
                return object(OT.self, customId: customId)
            }
            else if change.primaryValue != 0 {
                return object(OT.self, primaryId: change.primaryValue)
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }

    func insert<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?, validOnly: Bool = false) -> OT? {
        guard let change = change else {
            return nil
        }

        guard change.isValid || !validOnly else {
            return nil
        }

        let obj = OT(context: context)
        obj.apply(context: self, change: change)
        add([obj])

        return obj
    }
    
    func insert<OT: JVDatabaseModel>(of type: OT.Type, with changes: [JVDatabaseModelChange]?, validOnly: Bool = false) -> [OT] {
        guard let changes = changes else {
            return []
        }

        return changes.compactMap {
            insert(of: type, with: $0, validOnly: validOnly)
        }
    }
    
    func upsert<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?, validOnly: Bool = false) -> OT? {
        let (obj, _) = upsertCallback(of: type, with: change, validOnly: validOnly)
        return obj
    }
    
    func upsertCallback<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?, validOnly: Bool = false) -> (OT?, Bool) {
        var newlyAdded = false
        
        if let change = change, change.isValid {
            let obj: OT
            if let integerKey = change.integerKey {
                let customId = JVDatabaseModelCustomId(key: integerKey.key, value: integerKey.value)
                if let o = object(OT.self, customId: customId) {
                    obj = o
                    newlyAdded = false
                }
                else {
                    obj = OT(context: context)
                    newlyAdded = true
                }
            }
            else if let stringKey = change.stringKey {
                let customId = JVDatabaseModelCustomId(key: stringKey.key, value: stringKey.value)
                if let o = object(OT.self, customId: customId) {
                    obj = o
                    newlyAdded = false
                }
                else {
                    obj = OT(context: context)
                    newlyAdded = true
                }
            }
            else if change.primaryValue != 0 {
                if let o = object(OT.self, primaryId: change.primaryValue) {
                    obj = o
                    newlyAdded = false
                }
                else {
                    obj = OT(context: context)
                    newlyAdded = true
                }
            }
            else {
                obj = OT(context: context)
                newlyAdded = true
            }
            
            obj.apply(context: self, change: change)
            
            if obj.managedObjectContext == nil {
                add([obj])
            }
            
            return (obj, newlyAdded)
        }
        else {
            return (nil, false)
        }
    }
    
    func upsert<OT: JVDatabaseModel>(of type: OT.Type, with changes: [JVDatabaseModelChange]?) -> [OT] {
        if let changes = changes {
            return changes.compactMap { upsert(of: type, with: $0) }
        }
        else {
            return []
        }
    }
    
    func upsert<OT: JVDatabaseModel>(_ model: OT?, with change: JVDatabaseModelChange?) -> OT? {
        guard let change = change else {
            return model
        }
        
        if let model = model {
            model.apply(context: self, change: change)
            return model
        }
        else {
            return insert(of: OT.self, with: change)
        }
    }
    
    func update<OT: JVDatabaseModel>(of type: OT.Type, with change: JVDatabaseModelChange?) -> OT? {
        guard let change = change else {
            return nil
        }
        
        let obj: OT?
        if let integerKey = change.integerKey {
            let customId = JVDatabaseModelCustomId(key: integerKey.key, value: integerKey.value)
            if let foundObject = object(OT.self, customId: customId) {
                obj = foundObject
            }
            else if let stringKey = change.stringKey {
                let customId = JVDatabaseModelCustomId(key: stringKey.key, value: stringKey.value)
                obj = object(OT.self, customId: customId)
            }
            else {
                obj = nil
            }
        }
        else if let stringKey = change.stringKey {
            let customId = JVDatabaseModelCustomId(key: stringKey.key, value: stringKey.value)
            if let foundObject = object(OT.self, customId: customId) {
                obj = foundObject
            }
            else if let integerKey = change.integerKey {
                let customId = JVDatabaseModelCustomId(key: integerKey.key, value: integerKey.value)
                obj = object(OT.self, customId: customId)
            }
            else {
                obj = nil
            }
        }
        else if change.primaryValue != 0 {
            obj = object(OT.self, primaryId: change.primaryValue)
        }
        else {
            obj = nil
        }
        
        if let obj = obj, obj.jv_isValid {
            obj.apply(context: self, change: change)
        }
        
        return obj
    }
    
    func replaceAll<OT: JVDatabaseModel>(of type: OT.Type, with changes: [JVDatabaseModelChange]) -> [OT] {
        for object in objects(type, options: nil) {
            context.delete(object)
        }
        
        return upsert(of: type, with: changes)
    }
    
    func models<MT: JVDatabaseModel>(for IDs: [Int]) -> [MT] {
        return IDs.compactMap { self.object(MT.self, primaryId: $0) }
    }
    
    func agent(for agentID: Int, provideDefault: Bool) -> JVAgent? {
        if let value = object(JVAgent.self, primaryId: agentID) {
            return value
        }
        else if provideDefault {
            return upsert(of: JVAgent.self, with: JVAgentGeneralChange(placeholderID: agentID))
        }
        else {
            return nil
        }
    }
    
    func bot(for botID: Int, provideDefault: Bool) -> JVBot? {
        if let value = object(JVBot.self, primaryId: botID) {
            return value
        }
        else if provideDefault {
            return upsert(of: JVBot.self, with: JVBotGeneralChange(placeholderID: botID))
        }
        else {
            return nil
        }
    }
    
    func department(for departmentID: Int) -> JVDepartment? {
        if let value = object(JVDepartment.self, primaryId: departmentID) {
            return value
        }
        else {
            return nil
        }
    }
    
    func client(for clientID: Int, needsDefault: Bool) -> JVClient? {
        if let value = object(JVClient.self, primaryId: clientID) {
            return value
        }
        else if needsDefault {
            return upsert(of: JVClient.self, with: JVClientGeneralChange(clientID: clientID))
        }
        else {
            return nil
        }
    }
    
    func clientID(for chatID: Int) -> Int? {
        if let value = valueForKey(chatID) {
            return value
        }
        else {
            return chatWithID(chatID)?.client?.ID
        }
    }
    
    func chatWithID(_ ID: Int) -> JVChat? {
        return object(JVChat.self, primaryId: ID)
    }
    
    func messageWithUUID(_ UUID: String) -> JVMessage? {
        return object(JVMessage.self, customId: JVDatabaseModelCustomId(key: "m_uid", value: UUID))
    }
    
    func chatsWithClient(_ client: JVClient, includeArchived: Bool) -> [JVChat] {
        let predicate: NSPredicate
        if includeArchived {
            predicate = NSPredicate(format: "m_client.m_id == \(client.ID)")
        }
        else {
            predicate = NSPredicate(format: "m_client.m_id == \(client.ID) && m_is_archived == false")
        }

        return objects(
            JVChat.self,
            options: JVDatabaseRequestOptions(
                filter: predicate,
                sortBy: [],
                notificationName: nil
            )
        )
    }
    
    func createMessage(with change: JVDatabaseModelChange) -> JVMessage {
        let entityName = String(describing: JVMessage.self)
        let message = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as! JVMessage
        
        message.apply(context: self, change: change)
        add([message])
        
        return message
    }
    
    func messageWithCallID(_ callID: String?) -> JVMessage? {
        guard let callID = callID else { return nil }

        let filter = NSPredicate(format: "m_body.m_call_id == %@", callID)
        let options = JVDatabaseRequestOptions(filter: filter)
        return objects(JVMessage.self, options: options).last
    }
    
    func removeChat(_ chat: JVChat, cleanup: Bool) {
        if cleanup, let client = chat.client, client.jv_isValid {
            let messages = objects(
                JVMessage.self,
                options: JVDatabaseRequestOptions(
                    filter: NSPredicate(format: "m_client_id == %lld", client.ID),
                    sortBy: []
                )
            )
            
            customRemove(objects: messages, recursive: true)
        }
        
        context.delete(chat)
    }

    func removeMessages(uuids: [String]) {
        guard !uuids.isEmpty else { return }

        let messages = objects(
            JVMessage.self,
            options: JVDatabaseRequestOptions(
                filter: NSPredicate(format: "m_uid in %@", uuids)
            )
        )
        
        for message in messages {
            context.delete(message)
        }
    }
}
