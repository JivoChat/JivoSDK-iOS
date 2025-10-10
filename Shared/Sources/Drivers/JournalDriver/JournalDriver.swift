//
//  JournalDriver.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 20/06/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import XCGLogger

protocol IJournalDriver: AnyObject {
    var activeURL: URL { get }
    var fileSizeLimit: UInt64 { get }
    var lastLogURLs: [URL] { get }
    var level: JournalLevel { get set }
    func copy(to file: URL) -> JournalDriverArchivingStatus
    func archive(to file: URL) -> JournalDriverArchivingStatus
    func clear()
}

let JournalDriverBaseName = "com.jivosite.logger"
let JournalDriverLogger = XCGLogger(identifier: JournalDriverBaseName, includeDefaultDestinations: false)

enum JournalDriverArchivingStatus {
    case success
    case failedCutting
    case failedCompressing
}

struct JournalDestination: OptionSet {
    var rawValue: Int
    
    static let console = Self(rawValue: 1 << 0)
    static let file = Self(rawValue: 1 << 1)
    static let all: Self = [.console, .file]
}

final class JournalDriver: IJournalDriver {
    let activeURL: URL
    private let archiveURL: URL
    
    private let logger = JournalDriverLogger
    private let maximumFileSize = UInt64(10 * 1024 * 1024) // 10 MB
    
    var fileSizeLimit: UInt64 { return maximumFileSize }
    let fileDestination: AutoRotatingFileDestination
    
    init(activeURL: URL, archiveURL: URL, destination: JournalDestination) {
        self.activeURL = activeURL
        self.archiveURL = archiveURL
        
        let fileID = XCGLogger.Constants.systemLogDestinationIdentifier
        fileDestination = AutoRotatingFileDestination(owner: nil, writeToFile: activeURL, identifier: fileID, shouldAppend: true, appendMarker: "== Launched ==")
        fileDestination.targetMaxFileSize = maximumFileSize
        fileDestination.targetMaxTimeInterval = 0
        fileDestination.archiveFolderURL = archiveURL
        fileDestination.outputLevel = destination.contains(.file) ? .verbose : .none
        fileDestination.showLogIdentifier = false
        fileDestination.showFunctionName = false
        fileDestination.showLevel = false
        fileDestination.showFileName = false
        fileDestination.showLineNumber = false
        fileDestination.showDate = false
        fileDestination.logQueue = XCGLogger.logQueue
        if fileDestination.shouldRotate() { fileDestination.rotateFile() }
        
        let consoleID = XCGLogger.Constants.baseConsoleDestinationIdentifier
        let consoleDestination = ConsoleDestination(owner: nil, identifier: consoleID)
        consoleDestination.outputLevel = destination.contains(.console) ? .verbose : .none
        consoleDestination.showLogIdentifier = false
        consoleDestination.showFunctionName = false
        consoleDestination.showLevel = false
        consoleDestination.showFileName = false
        consoleDestination.showLineNumber = false
        consoleDestination.showDate = false
        
        logger.add(destination: fileDestination)
        logger.add(destination: consoleDestination)
        logger.logAppDetails()
    }
    
    var lastLogURLs: [URL] {
        let oldURLs = fileDestination.archivedFileURLs().prefix(1)
        return Array(oldURLs) + [activeURL]
    }
    
    var level: JournalLevel {
        get { globalJournalLevel }
        set { setJournalLevel(newValue) }
    }
    
    func copy(to file: URL) -> JournalDriverArchivingStatus {
        guard let limitedData = accumulateJournal() else {
            return .failedCutting
        }
        
        do {
            try limitedData.write(to: file)
            return .success
        }
        catch {
            return .failedCompressing
        }
    }
    
    func archive(to file: URL) -> JournalDriverArchivingStatus {
        guard let limitedData = accumulateJournal() else {
            return .failedCutting
        }
        
        do {
            let compressedData = try limitedData.gzipped(level: .bestCompression)
            try compressedData.write(to: file)
            return .success
        }
        catch {
            return .failedCompressing
        }
    }
    
    func clear() {
        try? Data().write(to: activeURL)
    }
    
    private func accumulateJournal() -> Data? {
        func _read(fileURL: URL?) -> String? {
            guard let url = fileURL else { return nil }
            guard let data = try? Data(contentsOf: url) else { return "<Cannot access the file>\n" }
            return String(data: data, encoding: .utf8) ?? "<Cannot read the file>\n"
        }
        
        var accumulatedRaw = String()
        lastLogURLs.compactMap(_read).forEach { slice in
            accumulatedRaw += "\n<next slice>\n\n"
            accumulatedRaw += slice
        }
        
        let limitSize = Int(fileSizeLimit * 3)
        let limitedRaw = String(accumulatedRaw.suffix(limitSize))
        
        return limitedRaw.data(using: .utf8)
    }
}
