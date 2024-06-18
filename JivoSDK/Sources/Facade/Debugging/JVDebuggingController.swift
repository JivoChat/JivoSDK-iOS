//
//  JivoSDKDebuggingImpl.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 07.06.2021.
//

import Foundation

/**
 ``Jivo``.``Jivo/debugging`` namespace for SDK debugging
 */
@objc(JVDebuggingController)
public final class JVDebuggingController: NSObject {
    /**
     Object that controls debugging process
     */
    @objc(delegate)
    public weak var delegate = JVDebuggingDelegate?.none {
        didSet {
            _delegateHookDidSet()
        }
    }
    
    /**
     Current level of logging verbosity
     */
    @objc(level)
    public var level = JVDebuggingLevel.full {
        didSet {
            _levelHookDidSet()
        }
    }
    
    /**
     Performs copying of local log entries
     and returns a link to the created copy
     via completion block with status
     
     - Parameter handler:
     The block that would be called when copying is finished
     */
    @objc(copyLogsWithCompletionHandler:)
    public func copyLogs(completion handler: @escaping (URL?, JVDebuggingArchiveStatus) -> Void) {
        _copyLogs(completion: handler)
    }

    /**
     Performs archiving of local log entries
     and returns a link to the created archive
     via completion block with status
     
     - Parameter handler:
     The block that would be called when an archive is ready
     */
    @objc(archiveLogsWithCompletionHandler:)
    public func archiveLogs(completion handler: @escaping (URL?, JVDebuggingArchiveStatus) -> Void) {
        _archiveLogs(completion: handler)
    }
    
    /**
     Presents a sharing screen of local log entries
     */
    @objc(exportLogsWithinParent:)
    public func exportLogs(within parent: UIViewController?) {
        _exportLogs(within: parent)
    }
}

extension JVDebuggingController: SdkEngineAccessing {
    private func _delegateHookDidSet() {
        setJournalCustomHandler { [unowned self] text in
            switch self.delegate?.jivoDebugging(catchEvent: .shared, text: text) {
            case nil:
                return true
            case .keep:
                return true
            case .ignore:
                return false
            }
        }
    }
    
    private func _levelHookDidSet() {
        switch level {
        case .silent:
            setJournalLevel(.silent)
        case .full:
            setJournalLevel(.full)
        }
    }
    
    private func _copyLogs(completion handler: @escaping (URL?, JVDebuggingArchiveStatus) -> Void) {
        let drivers = engine.drivers
        
        guard let tmpFile = drivers.cacheDriver.url(item: .accumulatedLogs) else {
            return handler(nil, .failedAccessing)
        }
        
        let originalQueue = OperationQueue.current ?? .main
        DispatchQueue.global(qos: .userInitiated).async {
            let status = drivers.journalDriver.copy(to: tmpFile)
            originalQueue.addOperation {
                switch status {
                case .success:
                    handler(tmpFile, .success)
                case .failedCutting:
                    handler(nil, .failedPreparing)
                case .failedCompressing:
                    handler(nil, .failedPreparing)
                }
            }
        }
    }
    
    private func _archiveLogs(completion handler: @escaping (URL?, JVDebuggingArchiveStatus) -> Void) {
        let drivers = engine.drivers
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd'T'HHmmss"
        let timepoint = formatter.string(from: Date())
        
        let uniqueChannel = engine.sessionContext.accountConfig?.channelId ?? "unknown"
        let uniqueName = "support-\(uniqueChannel)-\(timepoint).txt.gz"
        let uniqueItem = CacheDriverItem(fileName: uniqueName)

        guard let tmpFile = drivers.cacheDriver.url(item: uniqueItem) else {
            return handler(nil, .failedAccessing)
        }
        
        let originalQueue = OperationQueue.current ?? .main
        DispatchQueue.global(qos: .userInitiated).async {
            let status = drivers.journalDriver.archive(to: tmpFile)
            originalQueue.addOperation {
                switch status {
                case .success:
                    handler(tmpFile, .success)
                case .failedCutting:
                    handler(nil, .failedPreparing)
                case .failedCompressing:
                    handler(nil, .failedPreparing)
                }
            }
        }
    }
    
    private func _exportLogs(within parent: UIViewController?) {
        _archiveLogs { [unowned self] url, status in
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
    static let accumulatedLogs = CacheDriverItem(fileName: "support.txt.gz")
}
