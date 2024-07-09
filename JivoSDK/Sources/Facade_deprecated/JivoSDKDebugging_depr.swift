//
//  JivoSDK_Debugging.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 02.04.2023.
//

import Foundation

@available(*, deprecated)
@objc(JivoSDKDebugging)
public class JivoSDKDebugging: NSObject {
    @objc(level)
    public var level: JivoSDKDebuggingLevel = .full {
        didSet {
            Jivo.debugging.level = level.toNewAPI()
        }
    }
    
    @objc(archiveLogsWithCompletionHandler:)
    public func archiveLogs(completion: @escaping (URL?, JivoSDKArchivingStatus) -> Void) {
        Jivo.debugging.archiveLogs { url, status in
            completion(url, status.toNewAPI())
        }
    }
}

@available(*, deprecated)
@objc(JivoSDKDebuggingLevel)
public enum JivoSDKDebuggingLevel: Int {
    case silent
    case full
}

@available(*, deprecated)
@objc(JivoSDKArchivingStatus)
public enum JivoSDKArchivingStatus: Int {
    case success
    case failedAccessing
    case failedPreparing
}

@available(*, deprecated)
fileprivate extension JivoSDKDebuggingLevel {
    func toNewAPI() -> JVDebuggingLevel {
        switch self {
        case .silent:
            return .silent
        case .full:
            return .full
        }
    }
}

@available(*, deprecated)
fileprivate extension JVDebuggingArchiveStatus {
    func toNewAPI() -> JivoSDKArchivingStatus {
        switch self {
        case .failedAccessing:
            return .failedAccessing
        case .failedPreparing:
            return .failedPreparing
        case .success:
            return .success
        }
    }
}
