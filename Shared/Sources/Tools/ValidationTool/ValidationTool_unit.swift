//
//  ValidationToolUnit.swift
//  JivoMobile-Units
//
//  Created by Stan Potemkin on 08/12/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import XCTest
@testable import Jivo

class ValidationToolUnit: XCTestCase {
    private let tool = ValidationTool()
    
    func test_whenNameIsEmpty_thenToolDetectsItMissing() {
        do {
            if let error = tool.validateName(generate(length: 0)) {
                throw error
            }
            else {
                XCTFail()
            }
        }
        catch ValidationError.missing {
            XCTAssert(true)
        }
        catch {
            XCTFail()
        }
    }
    
    func test_whenNameIsUpTo128_thenToolDetectsItCorrect() {
        do {
            if let error = tool.validateName(generate(length: 1)) {
                throw error
            }
            
            if let error = tool.validateName(generate(length: 10)) {
                throw error
            }
            
            if let error = tool.validateName(generate(length: 100)) {
                throw error
            }
            
            if let error = tool.validateName(generate(length: 127)) {
                throw error
            }
            
            XCTAssert(true)
        }
        catch {
            XCTFail()
        }
    }

    func test_whenNameIs128AndLonger_thenToolDetectsItTooLong() {
        do {
            if let error = tool.validateName(generate(length: 128)) {
                throw error
            }
            else {
                XCTFail()
            }
        }
        catch ValidationError.tooLong {
            XCTAssert(true)
        }
        catch {
            XCTFail()
        }
    }
    
    func test_whenEmailIsRussian_thenToolDetectsItInvalid() {
        do {
            if let error = tool.validateEmail("привет@всем.рф", allowsEmpty: false) {
                throw error
            }
            else {
                XCTFail()
            }
        }
        catch ValidationError.invalid {
            XCTAssert(true)
        }
        catch {
            XCTFail()
        }
    }
    
    func test_whenEmailContainsRussian_thenToolDetectsItInvalid() {
        do {
            if let error = tool.validateEmail("hello@from.рф", allowsEmpty: false) {
                throw error
            }
            else {
                XCTFail()
            }
        }
        catch ValidationError.invalid {
            XCTAssert(true)
        }
        catch {
            XCTFail()
        }
    }
    
    func test_whenEmailContainsAscii_thenToolDetectsItCorrect() {
        do {
            if let error = tool.validateEmail("hello@from.rf", allowsEmpty: false) {
                throw error
            }
            else {
                XCTAssert(true)
            }
        }
        catch {
            XCTFail()
        }
    }
    
    func test_whenPhoneContainsAnotherSymbols_thenToolDetectsItIncorrect() {
        do {
            if let error = tool.validatePhone("call me: +79051234567") {
                throw error
            }
            else {
                XCTFail()
            }
        }
        catch ValidationError.invalid {
            XCTAssert(true)
        }
        catch {
            XCTFail()
        }
    }
    
    func test_whenPhoneContainsNothingElse_thenToolDetectsItCorrect() {
        do {
            if let error = tool.validatePhone("+79051234567") {
                throw error
            }
            else {
                XCTAssert(true)
            }
        }
        catch {
            XCTFail()
        }
    }
    
    func test_whenCommentIsUpTo128_thenToolDetectsItCorrect() {
        do {
            if let error = tool.validateComment(generate(length: 0)) {
                throw error
            }
            
            if let error = tool.validateComment(generate(length: 1)) {
                throw error
            }
            
            if let error = tool.validateComment(generate(length: 10)) {
                throw error
            }
            
            if let error = tool.validateComment(generate(length: 100)) {
                throw error
            }
            
            if let error = tool.validateComment(generate(length: 127)) {
                throw error
            }
            
            XCTAssert(true)
        }
        catch {
            XCTFail()
        }
    }
    
    func test_whenCommentIs128AndLonger_thenToolDetectsItTooLong() {
        do {
            if let error = tool.validateComment(generate(length: 128)) {
                throw error
            }
            else {
                XCTFail()
            }
        }
        catch ValidationError.tooLong {
            XCTAssert(true)
        }
        catch {
            XCTFail()
        }
    }

    private func generate(length: Int) -> String {
        return String(repeating: "N", count: length)
    }
}
