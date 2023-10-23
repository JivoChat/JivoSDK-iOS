//
//  TypingCacheServiceUnit.swift
//  TestFlow-Units
//
//  Created by Yulia Popova on 25.02.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import XCTest
import JMTimelineKit
@testable import App

final class TypingCacheServiceUnit: XCTestCase {
    private let textSamples = ["Test text", nil, "Test text2"]
    
    func testCacheString() {
        let sut = buildTypingCacheService()
        
        for sample in textSamples {
            sut.cache(text: sample)
            XCTAssertEqual(sut.currentInput.text, sample)
        }
    }
    
    func testCacheUncacheObject() {
        let sut = buildTypingCacheService()
        
        let attachment = createAttachment()
        
        XCTAssertEqual(sut.cache(attachment: attachment), .accept)
        XCTAssertEqual(sut.cache(attachment: attachment), .ignore)
        XCTAssertEqual(sut.currentInput.attachments, [attachment])
        
        sut.uncache(attachmentAt: 0)
        XCTAssertEqual(sut.currentInput.attachments.count, 0)
    }
    
    func testSaveAndResetInput() {
//        let sut = buildTypingCacheService()
//
//        let typingContext = TypingContext(kind: .chat, ID: 432)
//
//        sut.cache(text: textSamples[0])
//
//        sut.saveInput(context: typingContext, flush: false)
//        let cachedRecord = sut.obtainInput(context: typingContext)
//
//        XCTAssertEqual(cachedRecord?.text, textSamples[0])
//
//        let attachment2 = createAttachment()
//
//        XCTAssertEqual(sut.cache(attachment: attachment2), .accept)
//        XCTAssertEqual(cachedRecord?.attachments, [attachment2])
//
//        sut.resetInput(context: typingContext)
//        let currentInput = sut.obtainInput(context: typingContext)
//
//        XCTAssertNil(currentInput)
    }
    
    func testActivateInput() {
//        let sut = buildTypingCacheService()
//        let typingContext1 = TypingContext(kind: .chat, ID: 1)
//        let typingContext2 = TypingContext(kind: .chat, ID: 2)
//        
//        sut.cache(text: textSamples[0])
//        sut.saveInput(context: typingContext1, flush: false)
//        var cachedRecord = sut.obtainInput(context: typingContext1)
//        XCTAssertEqual(cachedRecord?.text, textSamples[0])
//
//        sut.cache(text: textSamples[1])
//        sut.saveInput(context: typingContext2, flush: false)
//        cachedRecord = sut.obtainInput(context: typingContext1)
//        XCTAssertEqual(cachedRecord?.text, textSamples[1])
//
//        _ = sut.activateInput(context: typingContext2)
//
//        let input = sut.activateInput(context: typingContext1)
//        XCTAssertEqual(input?.text, textSamples[0])
    }
    
    func testCanAttachMore() {
        let sut = buildTypingCacheService()
        
        for _ in 0..<sut.maximumCountOfAttachments {
            XCTAssertTrue(sut.canAttachMore)
            XCTAssertEqual(sut.cache(attachment: createAttachment()), .accept)
        }
        
        XCTAssertFalse(sut.canAttachMore)
        XCTAssertEqual(sut.cache(attachment: createAttachment()), .reject)
    }
    
    private func buildTypingCacheService() -> TypingCacheService {
        return TypingCacheService(
            fileURL: nil,
            agentsRepo: AgentsRepoMock(agents: .jv_empty),
            chatsRepo: ChatsRepoMock()
        )
    }
    
    private func createAttachment() -> ChatPhotoPickerObject {
        return ChatPhotoPickerObject(
            uuid: UUID(),
            payload: .file(.init(url: URL(fileURLWithPath: "test"), name: "test", size: 32, duration: 0)))
    }
}
