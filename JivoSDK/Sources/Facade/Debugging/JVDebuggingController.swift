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
    public var level = JVDebuggingLevel.silent {
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
        
        guard let tmpFile = drivers.cacheDriver.url(item: .accumulatedLogs) else {
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
}

extension CacheDriverItem {
    static let accumulatedLogs = CacheDriverItem(fileName: "jivosdk.logs.txt.gz")
}
