//
// Created by Stan Potemkin on 30/03/2018.
// Copyright (c) 2018 JivoSite. All rights reserved.
//

import Foundation

struct TypingContext: Hashable, Equatable, Codable {
    enum Kind: String, Codable { case chat, agent }
    let kind: Kind
    let ID: Int
}

extension TypingContext {
    static let standard = Self.init(kind: .chat, ID: 0)
}

enum TypingCacheAttachmentReaction {
    case accept
    case reject
    case ignore
}

enum InputMode: Int, Codable {
    case regular = 0
    case editing
    case comment
    case sms
    case whatsapp
    case email
}

protocol ITypingCacheService: AnyObject {
    func currentInput(context: TypingContext) -> TypingCacheInput
    func canAttachMore(context: TypingContext) -> Bool
    func cache(context: TypingContext, mode: InputMode)
    func cache(context: TypingContext, text: String?)
    func cache(context: TypingContext, attachment: PickedAttachmentObject) -> TypingCacheAttachmentReaction
    func discardAttachment(context: TypingContext, index: Int)
    func discardAllAttachments(context: TypingContext)
    func canUseAiSummarize(context: TypingContext) -> Bool
    func incSummarizeCount(context: TypingContext)
    func cacheWhatsAppTarget(context: TypingContext, number: String)
    func activateInput(context: TypingContext) -> TypingCacheInput
    func saveInput(context: TypingContext)
    func findInput(context: TypingContext) -> TypingCacheInput?
    func resetInput(context: TypingContext)
}

fileprivate let kAmountOfDaysToStoreRecords = 2

final class TypingCacheService: ITypingCacheService {
    private let fileURL: URL?
    private let attachmentsNumberLimit: Int
    private let agentsRepo: IAgentsRepo
    private let chatsRepo: IChatsRepo

    private var mutex = NSRecursiveLock()
    private var records = [TypingContext: TypingCacheRecord]()
    private var lastChatID = Int()
    
    init(fileURL: URL?, attachmentsNumberLimit: Int, agentsRepo: IAgentsRepo, chatsRepo: IChatsRepo) {
        self.fileURL = fileURL
        self.attachmentsNumberLimit = attachmentsNumberLimit
        self.agentsRepo = agentsRepo
        self.chatsRepo = chatsRepo

        read()
    }
    
    func currentInput(context: TypingContext) -> TypingCacheInput {
        if let record = findOptionalRecord(context: context) {
            return record
        }
        else {
            return TypingCacheRecord.init(
                context: context,
                text: .jv_empty,
                attachments: .jv_empty,
                mode: .regular,
                aiSummarizeNumber: 0,
                whatsappTarget: nil,
                actualityTimestamp: Date())
        }
    }
    
    func canAttachMore(context: TypingContext) -> Bool {
        if let record = findOptionalRecord(context: context) {
            return (record.attachments.count < attachmentsNumberLimit)
        }
        else {
            return true
        }
    }
    
    func cache(context: TypingContext, mode: InputMode) {
        requirePatchRecord(context: context) { record in
            record.mode = mode
        }
    }
    
    func cache(context: TypingContext, text: String?) {
        requirePatchRecord(context: context) { record in
            record.text = text?.jv_valuable
        }
    }
    
    func cacheWhatsAppTarget(context: TypingContext, number: String) {
        requirePatchRecord(context: context) { record in
            record.whatsappTarget = number.jv_valuable
        }
    }

    func cache(context: TypingContext, attachment: PickedAttachmentObject) -> TypingCacheAttachmentReaction {
        return requirePatchRecord(context: context) { record in
            if let index = record.attachments.firstIndex(where: { $0.uuid == attachment.uuid }) {
                record.attachments[index] = attachment
                return .ignore
            }
            else if !canAttachMore(context: context) {
                return .reject
            }
            else {
                record.attachments.append(attachment)
                return .accept
            }
        }
    }
    
    func discardAttachment(context: TypingContext, index: Int) {
        requirePatchRecord(context: context) { record in
            record.attachments.remove(at: index)
        }
    }
    
    func discardAllAttachments(context: TypingContext) {
        requirePatchRecord(context: context) { record in
            record.attachments.removeAll()
        }
    }
    
    func incSummarizeCount(context: TypingContext) {
        requirePatchRecord(context: context) { record in
            record.aiSummarizeNumber += 1
        }
    }
    
    func canUseAiSummarize(context: TypingContext) -> Bool {
        if let record = findOptionalRecord(context: context) {
            return (record.aiSummarizeNumber < 3)
        }
        else {
            return true
        }
    }
    
    func activateInput(context: TypingContext) -> TypingCacheInput {
        return findRequiredRecord(context: context)
    }
    
    func saveInput(context: TypingContext) {
        guard let record = findOptionalRecord(context: context) else {
            return
        }
        
        if record.isEmpty {
            resetInput(context: context)
        }
        else {
            applyDraft(record.text, to: context)
            save()
        }
    }
    
    func findInput(context: TypingContext) -> TypingCacheInput? {
        return findOptionalRecord(context: context)
    }
    
    func resetInput(context: TypingContext) {
        mutex.lock()
        records.removeValue(forKey: context)
        mutex.unlock()
        
        applyDraft(nil, to: context)
        save()
    }
    
    private func findOptionalRecord(context: TypingContext) -> TypingCacheRecord? {
        let record = records.jv_value(forKey: context, locking: mutex)
        return record
    }
    
    private func findRequiredRecord(context: TypingContext) -> TypingCacheRecord {
        if let record = findOptionalRecord(context: context) {
            return record
        }
        else {
            let record = TypingCacheRecord(context: context)
            
            mutex.lock()
            records[context] = record
            mutex.unlock()
            
            return record
        }
    }
    
    @discardableResult
    private func requirePatchRecord<Value>(context: TypingContext, block: (inout TypingCacheRecord) -> Value) -> Value {
        var record = findRequiredRecord(context: context)
        let value = block(&record)
        
        mutex.lock()
        records[context] = record
        mutex.unlock()
        
        return value
    }
    
    private func read() {
        guard let url = fileURL else {
            return
        }
        
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            self.records = .jv_empty
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let allRecords = try JSONDecoder().decode([TypingContext:TypingCacheRecord].self, from: data)
            
            let recentRecords = allRecords.filter {
                let days = $0.value.actualityTimestamp.getInterval(toDate: nil, component: .day)
                return (days < kAmountOfDaysToStoreRecords)
            }
            
            self.records = recentRecords
        }
        catch let exc {
            debugPrint(exc)
        }
    }

    private func save() {
        guard let url = fileURL else {
            return
        }
        
        do {
            mutex.lock()
            defer {
                mutex.unlock()
            }
            
            let data = try JSONEncoder().encode(records)
            try data.write(to: url, options: .atomic)
        }
        catch let exc {
            debugPrint(exc)
        }
    }

    private func applyDraft(_ draft: String?, to context: TypingContext) {
        switch context.kind {
        case .chat:
            chatsRepo.updateDraft(id: context.ID, currentText: draft)
        case .agent:
            agentsRepo.updateDraft(id: context.ID, currentText: draft)
        }
    }
}
