//
//  PureParserToolUnit.swift
//  JivoMobile-Units
//
//  Created by Stan Potemkin on 25/03/2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import XCTest
open class PureParserToolUnit: XCTestCase {
    private let tool = PureParserTool()
    
    public func test_plainSource() {
        let result = tool.execute("Please wait.", collapseSpaces: true)
        
        XCTAssertEqual(result, "Please wait.")
    }
    
    public func test_assignedVariable() {
        tool.assign(variable: "name", value: "Stan")
        let result = tool.execute("Please wait, $name", collapseSpaces: true)
        
        XCTAssertEqual(result, "Please wait, Stan")
    }
    
    public func test_unassignedVariable() {
        let result = tool.execute("Please wait, $name", collapseSpaces: true)
        
        XCTAssertEqual(result, String())
    }
    
    public func test_variableAndBlockFrame() {
        tool.assign(variable: "name", value: "Stan")
        tool.assign(variable: "anotherName", value: "Pavel")
        let result = tool.execute("Please wait, $name. We're sending that to $[$anotherName ## another agent].", collapseSpaces: true)
        
        XCTAssertEqual(result, "Please wait, Stan. We're sending that to Pavel.")
    }
    
    public func test_variableAndSkippedBlock() {
        tool.assign(variable: "name", value: "Stan")
        let result = tool.execute("Please wait, $name. We're sending that to $[$anotherName ## another agent].", collapseSpaces: true)
        
        XCTAssertEqual(result, "Please wait, Stan. We're sending that to another agent.")
    }
    
    public func test_variableAndBlockAlias() {
        tool.assign(variable: "name", value: "Stan")
        tool.activate(alias: "your-self", false)
        let result = tool.execute("Please wait, $name. We're sending that to $[$anotherName ## :your-self: yourself ## another agent].", collapseSpaces: true)
        
        XCTAssertEqual(result, "Please wait, Stan. We're sending that to another agent.")
    }
    
    public func test_blockFrame() {
        tool.assign(variable: "folder", value: "Inbox")
        let result = tool.execute("Congrats! You saved it $[in folder '$folder'].", collapseSpaces: true)
        
        XCTAssertEqual(result, "Congrats! You saved it in folder 'Inbox'.")
    }
    
    public func test_skippedBlockWithoutTrimming() {
        let result = tool.execute("Congrats! You saved it $[in folder '$folder'].", collapseSpaces: false)
        
        XCTAssertEqual(result, "Congrats! You saved it .")
    }
    
    public func test_skippedBlockWithTrimming() {
        let result = tool.execute("Congrats! You saved it $[in folder '$folder'].", collapseSpaces: true)
        
        XCTAssertEqual(result, "Congrats! You saved it.")
    }
    
    public func test_skippedBlockWithExtraSpaceAndTrimming() {
        let result = tool.execute("Congrats! You saved it $[in folder '$folder']. ", collapseSpaces: true)
        
        XCTAssertEqual(result, "Congrats! You saved it.")
    }
    
    public func test_reminderFromAnotherAgent() {
        tool.assign(variable: "creatorName", value: "Stan")
        tool.assign(variable: "comment", value: "Hello")
        tool.activate(alias: "target", false)
        tool.assign(variable: "date", value: "today")
        tool.assign(variable: "time", value: "12:00")
        let result = tool.execute("$[Agent $creatorName ## You] changed reminder $[«$comment»] $[:target: for $[$targetName ## you]] on $date at $time", collapseSpaces: true)
        
        XCTAssertEqual(result, "Agent Stan changed reminder «Hello» on today at 12:00")
    }
    
    public func test_reminderFromMyself() {
        tool.assign(variable: "comment", value: "Hello")
        tool.activate(alias: "target", false)
        tool.assign(variable: "date", value: "today")
        tool.assign(variable: "time", value: "12:00")
        let result = tool.execute("$[Agent $creatorName ## You] changed reminder $[«$comment»] $[:target: for $[$targetName ## you]] on $date at $time", collapseSpaces: true)
        
        XCTAssertEqual(result, "You changed reminder «Hello» on today at 12:00")
    }
}
