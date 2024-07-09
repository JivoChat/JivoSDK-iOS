//
//  BaseChattingSubStorage.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 03.09.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation

protocol IBaseChattingSubStorage: ICommonSubStorage {
    func placeHistoryPointer(flag: JVMessageFlags, to newMessage: MessageEntity)
    func moveHistoryPointer(flag: JVMessageFlags, from oldMessage: MessageEntity, to newMessage: MessageEntity?)
    func resetHistoryPointers(flag: JVMessageFlags, amongIds: [Int])
    func flushQuoteToHistory(message: MessageEntity)
}

class BaseChattingSubStorage: CommonSubStorage, IBaseChattingSubStorage {
    let systemMessagingService: ISystemMessagingService
    
    init(userContext: AnyObject, databaseDriver: JVIDatabaseDriver, systemMessagingService: ISystemMessagingService) {
        self.systemMessagingService = systemMessagingService
        
        super.init(
            userContext: userContext,
            databaseDriver: databaseDriver)
    }
    
    func placeHistoryPointer(flag: JVMessageFlags, to newMessage: MessageEntity) {
        databaseDriver.readwrite { context in
            _ = context.update(of: MessageEntity.self, with: JVMessageFlagsChange(
                ID: newMessage.ID,
                flags: newMessage.flags.union(flag)
            ))
        }
    }
    
    func moveHistoryPointer(flag: JVMessageFlags, from oldMessage: MessageEntity, to newMessage: MessageEntity?) {
        databaseDriver.readwrite { context in
            _ = context.update(of: MessageEntity.self, with: JVMessageFlagsChange(
                ID: oldMessage.ID,
                flags: oldMessage.flags.subtracting(flag)
            ))
            
            if let newMessage = newMessage {
                _ = context.update(of: MessageEntity.self, with: JVMessageFlagsChange(
                    ID: newMessage.ID,
                    flags: newMessage.flags.union(flag)
                ))
            }
        }
    }
    
    func resetHistoryPointers(flag: JVMessageFlags, amongIds: [Int]) {
        databaseDriver.readwrite { context in
            let messages = context.objects(
                MessageEntity.self,
                options: JVDatabaseRequestOptions(
                    filter: NSPredicate(
                        format: "m_id in %@ AND (m_flags & %lld) > 0",
                        argumentArray: [amongIds.map(UInt64.init), flag.rawValue]
                    )
                )
            )
            
            messages.forEach { message in
                message.apply(
                    context: context,
                    change: JVMessageFlagsChange(
                        ID: message.ID,
                        flags: message.flags.subtracting(flag)
                    )
                )
            }
        }
    }
    
    func flushQuoteToHistory(message: MessageEntity) {
        databaseDriver.readwrite { context in
            _ = context.update(of: MessageEntity.self, with: JVMessageFlagsChange(
                ID: message.ID,
                flags: message.flags
                    .subtracting(.detachedFromHistory)
                    .union([.edgeToHistoryPast, .edgeToHistoryFuture])
            ))
        }
    }
}
