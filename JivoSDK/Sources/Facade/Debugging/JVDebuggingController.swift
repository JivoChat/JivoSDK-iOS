//
//  JivoSDKDebuggingImpl.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 07.06.2021.
//

import Foundation
import UIKit

/**
 ``Jivo``.``Jivo/debugging`` namespace for SDK debugging
 */
@objc(JVDebuggingController)
public final class JVDebuggingController: NSObject {
    /**
     Current level of logging verbosity
     */
    public func setLevel(_ level: JVDebuggingLevel) {
        _setLevel(level)
    }
    
    @objc(__setLevelName:)
    public func __setLevel(_ levelName: String) {
        if let level = JVDebuggingLevel(rawValue: levelName) {
            _setLevel(level)
        }
    }
    
    /**
     Performs copying of local log entries
     and returns a link to the created copy
     via completion block with status
     
     - Parameter handler:
     The block that would be called when copying is finished
     */
    public func exportCopy(completion handler: @escaping (JVDebuggingExportStatus, URL?) -> Void) {
        _exportCopy(completion: handler)
    }

    @objc(__exportCopyWithCompletionHandler:)
    public func __exportCopy(completion handler: @escaping (Int, URL?) -> Void) {
        _exportCopy { status, url in
            let s = JVDebuggingExportStatus.allCases.firstIndex(of: status) ?? .zero
            handler(s, url)
        }
    }

    /**
     Performs archiving of local log entries
     and returns a link to the created archive
     via completion block with status
     
     - Parameter handler:
     The block that would be called when an archive is ready
     */
    public func exportArchive(completion handler: @escaping (JVDebuggingExportStatus, URL?) -> Void) {
        _exportArchive(completion: handler)
    }
    
    @objc(__exportArchiveWithCompletionHandler:)
    public func __exportArchive(completion handler: @escaping (Int, URL?) -> Void) {
        _exportArchive { status, url in
            let s = JVDebuggingExportStatus.allCases.firstIndex(of: status) ?? .zero
            handler(s, url)
        }
    }
    
    /**
     Presents a sharing screen of local log entries
     */
    @objc(exportUIWithinParent:)
    public func exportUI(within parent: UIViewController?) {
        _exportUI(within: parent)
    }
    
    /**
     Assign a listener for each time SDK is going to log event,
     here you are able to replace the standard behavior with your own implementation
     */
    public func listenToRecord(original behavior: JVDebuggingOriginalRecordBehavior, callback: @escaping (_ entry: String) -> Void) {
        _listenToEvents { entry in
            callback(entry)
            return behavior
        }
    }
    
    @objc(__listenToRecordWithOriginalBehavior:handler:)
    public func __listenToRecord(original behaviorName: String, handler: @escaping (_ entry: String) -> Void) {
        if let behavior = JVDebuggingOriginalRecordBehavior(rawValue: behaviorName) {
            _listenToEvents { entry in
                handler(entry)
                return behavior
            }
        }
    }
}

extension JVDebuggingController: SdkEngineAccessing {
    private func _setLevel(_ level: JVDebuggingLevel) {
        switch level {
        case .silent:
            setJournalLevel(.silent)
        case .full:
            setJournalLevel(.full)
        }
    }
    
    private func _listenToEvents(callback: @escaping (_ text: String) -> JVDebuggingOriginalRecordBehavior) {
        setJournalCustomHandler { text in
            switch callback(text) {
            case .store:
                return true
            case .ignore:
                return false
            }
        }
    }
    
    private func _exportCopy(completion handler: @escaping (JVDebuggingExportStatus, URL?) -> Void) {
        let drivers = engine.drivers
        
        guard let tmpFile = drivers.cacheDriver.url(item: .accumulatedLogs) else {
            return handler(.failedAccessing, nil)
        }
        
        let originalQueue = OperationQueue.current ?? .main
        DispatchQueue.global(qos: .userInitiated).async {
            let status = drivers.journalDriver.copy(to: tmpFile)
            originalQueue.addOperation {
                switch status {
                case .success:
                    handler(.success, tmpFile)
                case .failedCutting:
                    handler(.failedPreparing, nil)
                case .failedCompressing:
                    handler(.failedPreparing, nil)
                }
            }
        }
    }
    
    private func _exportArchive(completion handler: @escaping (JVDebuggingExportStatus, URL?) -> Void) {
        let drivers = engine.drivers
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd'T'HHmmss"
        let timepoint = formatter.string(from: Date())
        
        let uniqueChannel = engine.sessionContext.accountConfig?.channelId ?? "unknown"
        let uniqueName = "support-\(uniqueChannel)-\(timepoint).txt.gz"
        let uniqueItem = CacheDriverItem(fileName: uniqueName)

        guard let tmpFile = drivers.cacheDriver.url(item: uniqueItem) else {
            return handler(.failedAccessing, nil)
        }
        
        let originalQueue = OperationQueue.current ?? .main
        DispatchQueue.global(qos: .userInitiated).async {
            let status = drivers.journalDriver.archive(to: tmpFile)
            originalQueue.addOperation {
                switch status {
                case .success:
                    handler(.success, tmpFile)
                case .failedCutting:
                    handler(.failedPreparing, nil)
                case .failedCompressing:
                    handler(.failedPreparing, nil)
                }
            }
        }
    }
    
    private func _exportUI(within parent: UIViewController?) {
        _exportArchive { [unowned self] status, url in
            guard let url else {
                return
            }
            
            engine.bridges.popupPresenterBridge.share(
                within: .specific(parent),
                items: [url],
                performCleanup: true)
        }
    }
}

extension CacheDriverItem {
    static let accumulatedLogs = CacheDriverItem(fileName: "support.txt")
}
