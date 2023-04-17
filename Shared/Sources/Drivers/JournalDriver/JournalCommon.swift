//
//  JournalCommon.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 01/06/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation
import XCGLogger
import SwiftGraylog

fileprivate let globalJournalQueue = prepareLoggingQueue()
fileprivate(set) var globalJournalLevel = JournalLevel.full
fileprivate(set) var globalJournalCustomHandler: ((String) -> Bool)?

fileprivate var globalJournalRecentCall = UUID()
fileprivate var globalJournalHistory = [UUID]()

fileprivate let silentGenerator = JournalSilentGenerator()
fileprivate let compactGenerator = JournalCompactGenerator()
fileprivate let fullGenerator = JournalFullGenerator()

enum JournalSubsystem: String {
    case auth
    case general
    case guests
    case phone
    case tools
    case worktime
    case any
}

struct JournalDebuggingToken {
    let value: String
}

enum JournalLayer: String {
    case debug
    case user
    case logic
    case system
    case network
    case backend
}

enum JournalLevel: String {
    case silent
    case compact
    case full
}

struct JournalTarget: OptionSet {
    let rawValue: Int
}
extension JournalTarget {
    static let local = JournalTarget(rawValue: 1 << 0)
    static let remote = JournalTarget(rawValue: 1 << 1)
    static let custom = JournalTarget(rawValue: 1 << 2)
}

struct JournalMeta {
    let call: UUID
    let file: String
    let line: Int
    let function: String
    let scope: Any?
    let target: JournalTarget
    let layer: JournalLayer
    let subsystem: JournalSubsystem
    let pointOfInterest: String?
    let debugging: JournalDebuggingToken?
    let unimessage: () -> AnyHashable
}

struct JournalChild {
    let file: String
    let call: UUID?
    
    init(file: String = #file, call: UUID?) {
        self.file = file
        self.call = call
    }
    
    @discardableResult
    func journal(line: Int = #line,
                 function: String = #function,
                 scope: Any? = nil,
                 target: JournalTarget = .local + .custom,
                 layer: JournalLayer = .debug,
                 subsystem: JournalSubsystem = .any,
                 pointOfInterest: String? = nil,
                 debugging: JournalDebuggingToken? = nil,
                 unimessage: @escaping () -> AnyHashable
    ) -> JournalChild {
        guard
            let call = call
        else {
            return JournalChild(file: file, call: nil)
        }
        
        let meta = JournalMeta(
            call: call,
            file: file,
            line: line,
            function: function,
            scope: scope,
            target: target,
            layer: layer,
            subsystem: subsystem,
            pointOfInterest: pointOfInterest,
            debugging: debugging,
            unimessage: unimessage
        )
        
        let generator: JournalGenerator = {
            switch globalJournalLevel {
            case .silent:
                return silentGenerator
            case .compact:
                return compactGenerator
            case .full:
                return fullGenerator
            }
        }()
        
        if generator.isEnabled {
            globalJournalQueue.addOperation {
                let message = generator.generateEntry(
                    meta: meta,
                    recentCall: globalJournalRecentCall,
                    historyOfCalls: globalJournalHistory)
                
                if target.contains(.custom) {
                    if globalJournalCustomHandler?(message) == false {
                        return
                    }
                }
                
                if target.contains(.local) {
                    globalJournalQueue.addOperation {
                        JournalDriverLogger.logln(.debug, functionName: String()) {
                            globalJournalRecentCall = meta.call
                            globalJournalHistory = (globalJournalHistory + [meta.call]).suffix(100)
                            return message + "\n"
                        }
                    }
                }
                
                if target.contains(.remote), let key = pointOfInterest {
                    Graylog.jv_send(
                        brief: key,
                        details: message,
                        file: file,
                        line: line,
                        includeCaches: true)
                }
            }
        }
        
        return JournalChild(
            file: file,
            call: call
        )
    }
}

class JournalGenerator {
    private let dateFormatter = DateFormatter()
    
    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }
    
    var isEnabled: Bool {
        return true
    }
    
    func generateEntry(meta: JournalMeta, recentCall: UUID, historyOfCalls: [UUID]) -> String {
        return String()
    }
    
    func formatFile(value: String) -> String {
        return URL(fileURLWithPath: value).lastPathComponent
    }
    
    func formatDate() -> String {
        return dateFormatter.string(from: Date())
    }
    
    func formatFunction(value: String) -> String {
        return value
            .replacingOccurrences(of: "JivoMobile_dev.", with: String())
            .replacingOccurrences(of: "JivoMobile.", with: String())
            .replacingOccurrences(of: "Jivo.", with: String())
    }
    
    func formatMessage(value: AnyHashable) -> String {
        switch value {
        case let value as String:
            return value
        case let value as [String]:
            return value.joined(separator: "\n") + "\n"
        default:
            return String(describing: value)
        }
    }
}

class JournalFullGenerator: JournalGenerator {
    private let separator = String(repeating: "-", count: 64)
    private let prefix = "|"
    private let infix = "|"
    
    override func generateEntry(meta: JournalMeta, recentCall: UUID, historyOfCalls: [UUID]) -> String {
        if meta.call == recentCall {
            return generateBody(meta: meta, startsWithPrefix: false)
        }
        else {
            let header = generateHeader(meta: meta, historyOfCalls: historyOfCalls)
            let body = generateBody(meta: meta, startsWithPrefix: true)
            return [header, body].joined(separator: "\n\(prefix)\n")
        }
    }

    private func generateHeader(meta: JournalMeta, historyOfCalls: [UUID]) -> String {
        let callArg: String
        if historyOfCalls.contains(meta.call) {
            callArg = "#->\(meta.call.uuidString.prefix(8).lowercased())"
        }
        else {
            callArg = "#\(meta.call.uuidString.prefix(8).lowercased())"
        }
        
        if let scope = meta.scope {
            return "\(separator)\n\(prefix) \(callArg) \(infix) \(formatFile(value: meta.file)) \(infix) \(type(of: scope))"
        }
        else {
            return "\(separator)\n\(prefix) \(callArg) \(infix) \(formatFile(value: meta.file))"
        }
    }
    
    private func generateBody(meta: JournalMeta, startsWithPrefix: Bool) -> String {
        let titleArgs = [formatDate(), "@\(meta.layer)/\(meta.subsystem)"]
        let title = titleArgs.joined(separator: " ")
        let subtitle = "\(formatFunction(value: meta.function)) :\(meta.line)"
        let body = formatMessage(value: meta.unimessage())
        
        let tokenRow = meta.debugging.flatMap({ "\n\(prefix) [D] <\($0.value)>" }) ?? String()
        let base = "[I] \(title)\n\(prefix) [L] \(subtitle)\(tokenRow)\n\n\(body)"
        return (
            startsWithPrefix
            ? "\(prefix) \(base)"
            : base
        )
    }
}

class JournalCompactGenerator: JournalGenerator {
    override func generateEntry(meta: JournalMeta, recentCall: UUID, historyOfCalls: [UUID]) -> String {
        let header = generateHeader(meta: meta)
        let body = generateBody(meta: meta)
        return [header, body].joined(separator: "\n")
    }

    private func generateHeader(meta: JournalMeta) -> String {
        return "\(formatFile(value: meta.file)):\(meta.line)"
    }
    
    private func generateBody(meta: JournalMeta) -> String {
        return formatMessage(value: meta.unimessage())
    }
}

class JournalSilentGenerator: JournalGenerator {
    override var isEnabled: Bool {
        return false
    }
}

func setJournalLevel(_ level: JournalLevel) {
    globalJournalQueue.addOperation { globalJournalLevel = level }
}

func setJournalCustomHandler(block: @escaping (String) -> Bool) {
    globalJournalCustomHandler = block
}

@discardableResult
func journal(file: String = #file,
             line: Int = #line,
             function: String = #function,
             scope: Any? = nil,
             target: JournalTarget = .local + .custom,
             layer: JournalLayer = .debug,
             subsystem: JournalSubsystem = .any,
             pointOfInterest: String? = nil,
             debugging: JournalDebuggingToken? = nil,
             unimessage: @escaping () -> AnyHashable) -> JournalChild {
    let child = JournalChild(
        file: file,
        call: UUID()
    )
    
    child.journal(
        line: line,
        function: function,
        scope: scope,
        target: target,
        layer: layer,
        subsystem: subsystem,
        pointOfInterest: pointOfInterest,
        debugging: debugging,
        unimessage: unimessage)
    
    return child
}

@discardableResult
func journal(file: String = #file,
             line: Int = #line,
             function: String = #function,
             layer: JournalLayer = .debug,
             subsystem: JournalSubsystem = .any,
             messages: [JournalLevel: () -> String]) -> JournalChild {
    guard
        let message = messages[globalJournalLevel]
    else {
        return JournalChild(
            file: file,
            call: nil
        )
    }
    
    return journal(
        file: file,
        line: line,
        function: function,
        layer: layer,
        subsystem: subsystem,
        unimessage: message
    )
}

@discardableResult
func debug(function: String = #function,
           file: String = #file,
           line: Int = #line,
           _ message: @escaping () -> String
           ) -> JournalChild {
    return journal(
        file: file,
        line: line,
        function: function,
        layer: .debug,
        subsystem: .any,
        unimessage: message
    )
}

fileprivate func prepareLoggingQueue() -> OperationQueue {
    let queue = OperationQueue()
    queue.name = "com.jivosite.logging-queue"
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .background
    return queue
}
