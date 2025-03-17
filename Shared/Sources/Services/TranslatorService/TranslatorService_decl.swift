//
//  TranslatorService_decl.swift
//  App
//
//  Created by Stan Potemkin on 22.11.2024.
//

import Foundation

protocol ITranslatorService: AnyObject {
    func state(of message: MessageEntity) -> TranslatorMessageState
    func requestTranslation(of message: MessageEntity)
    func storeTranslation(text: String, for message: MessageEntity)
    func findTranslation(for message: MessageEntity) -> String?
    func presentation(of message: MessageEntity) -> TranslatorMessagePresentation?
    func assignPresentation(_ presentation: TranslatorMessagePresentation, for message: MessageEntity)
    func swapPresentation(of message: MessageEntity)
    func clear()
}

enum TranslatorMessageState {
    case initial
    case awaiting
    case translated(presentation: TranslatorMessagePresentation)
}

enum TranslatorMessagePresentation {
    case original
    case translation
}
