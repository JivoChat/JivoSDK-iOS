//
//  TranslatorService.swift
//  App
//
//  Created by Stan Potemkin on 21.11.2024.
//

import Foundation

final class TranslatorService: ITranslatorService {
    private let localeProvider: JVILocaleProvider
    private let requestPerformer: (MessageEntity, String, String) -> Void
    
    private var messageIdToStateMap = [Int: State]()
    private var messageIdsWithEnabledTranslation = Set<Int>()
    
    private let autodetectLangId = ""
    
    init(localeProvider: JVILocaleProvider, requestPerformer: @escaping (MessageEntity, String, String) -> Void) {
        self.localeProvider = localeProvider
        self.requestPerformer = requestPerformer
    }
    
    func state(of message: MessageEntity) -> TranslatorMessageState {
        switch messageIdToStateMap[message.ID] {
        case .translated:
            let presentation = presentation(of: message) ?? .original
            return .translated(presentation: presentation)
        case .requested:
            return .awaiting
        case nil:
            return .initial
        }
    }
    
    func requestTranslation(of message: MessageEntity) {
        messageIdToStateMap[message.ID] = .requested
        requestPerformer(message, autodetectLangId, localeProvider.activeLang.rawValue)
    }
    
    func storeTranslation(text: String, for message: MessageEntity) {
        messageIdToStateMap[message.ID] = .translated(text)
        messageIdsWithEnabledTranslation.insert(message.ID)
    }
    
    func findTranslation(for message: MessageEntity) -> String? {
        if !messageIdsWithEnabledTranslation.contains(message.ID) {
            return nil
        }
        else if case .translated(let text) = messageIdToStateMap[message.ID] {
            return text
        }
        else {
            return nil
        }
    }
    
    func presentation(of message: MessageEntity) -> TranslatorMessagePresentation? {
        if !messageIdToStateMap.keys.contains(message.ID) {
            return nil
        }
        
        if messageIdsWithEnabledTranslation.contains(message.ID) {
            return .translation
        }
        else {
            return .original
        }
    }
    
    func assignPresentation(_ presentation: TranslatorMessagePresentation, for message: MessageEntity) {
        switch presentation {
        case .original:
            messageIdsWithEnabledTranslation.remove(message.ID)
        case .translation:
            messageIdsWithEnabledTranslation.insert(message.ID)
        }
    }
    
    func swapPresentation(of message: MessageEntity) {
        if presentation(of: message) == .original {
            assignPresentation(.translation, for: message)
        }
        else {
            assignPresentation(.original, for: message)
        }
    }
    
    func clear() {
        messageIdToStateMap.removeAll()
        messageIdsWithEnabledTranslation.removeAll()
    }
}

fileprivate extension TranslatorService {
    enum State {
        case requested
        case translated(String)
    }
}
