//
//  ChatTimelineProvider.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 29/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import JMTimelineKit
import JMMarkdownKit
import Gzip
import JMCodingKit

protocol JVChatTimelineProvider: JMTimelineProvider {
    func mentionProvider(origin: JMMarkdownMentionOrigin) -> JMMarkdownMentionMeta?
    func retrieveResource(from url: URL, canvasWidth: CGFloat, completion: @escaping (RemoteStorageFileResource?) -> Void)
    func requestWaveformPoints(from url: URL, completion: @escaping (RemoteStorageFileResource?) -> Void)
}

final class ChatTimelineProvider: JVChatTimelineProvider {
    private let client: ClientEntity?
    private let endpointAccessorProvider: () -> IKeychainAccessor
    private let formattingProvider: IFormattingProvider
    private let remoteStorageService: IRemoteStorageService
    private let mentionProviderBridge: JMMarkdownMentionProvider
    
    init(client: ClientEntity?,
         endpointAccessorProvider: @escaping () -> IKeychainAccessor,
         formattingProvider: IFormattingProvider,
         remoteStorageService: IRemoteStorageService,
         mentionProvider: @escaping JMMarkdownMentionProvider) {
        self.client = client
        self.endpointAccessorProvider = endpointAccessorProvider
        self.formattingProvider = formattingProvider
        self.remoteStorageService = remoteStorageService
        self.mentionProviderBridge = mentionProvider
    }
    
    func formattedDateForGroupHeader(_ date: Date) -> String {
        return formattingProvider.format(date: date, style: .dayHeader)
    }
    
    func formattedDateForMessageEvent(_ date: Date) -> String {
        return formattingProvider.format(date: date, style: .messageTime)
    }
    
    func formattedTimeForPlayback(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        return formattingProvider.format(date: date, style: .playbackTime)
    }
    
    func formattedPhoneNumber(_ phone: String) -> String {
        if let client = jv_validate(client) {
            return formattingProvider.format(phone: phone, style: .printable, countryCode: client.countryCode, supportsFallback: false)
        }
        else {
            return formattingProvider.format(phone: phone, style: .printable, countryCode: nil, supportsFallback: false)
        }
    }
    
    func mentionProvider(origin: JMMarkdownMentionOrigin) -> JMMarkdownMentionMeta? {
        return mentionProviderBridge(origin)
    }
    
    func retrieveResource(from url: URL, canvasWidth: CGFloat, completion: @escaping (RemoteStorageFileResource?) -> Void) {
        remoteStorageService.retrieveFile(
            endpoint: endpointAccessorProvider().string,
            originURL: url,
            quality: .preview(width: canvasWidth),
            caching: .enabled,
            on: .main,
            callback: completion)
    }
    
    func requestWaveformPoints(from url: URL, completion: @escaping (RemoteStorageFileResource?) -> Void) {
        remoteStorageService.retrieveFile(
            endpoint: endpointAccessorProvider().string,
            originURL: url,
            quality: .preview(width: CGFloat(1024)),
            caching: .enabled,
            on: .main,
            callback: completion
        )
    }
    
    func retrieveMeta(forFileWithURL fileURL: URL, completion: @escaping (JMTimelineMediaMetaResult) -> Void) {
        remoteStorageService.retrieveMeta(
            endpoint: endpointAccessorProvider().string,
            originURL: fileURL,
            caching: .enabled,
            on: .main,
            completion: { result in
                switch result {
                case let .success(fileMeta):
                    completion(.meta(fileName: fileMeta.name))
                case .failure(.unauthorized):
                    completion(.accessDenied(description: loc["JV_FileAttachment_LinkStatus_Expired", "file_download_expired"]))
                case .failure(.notFromCloudStorage):
                    completion(.metaIsNotNeeded())
                default:
                    completion(.unknownError(description: loc["JV_FileAttachment_LinkStatus_Unavailable", "file_download_unavailable"]))
                }
            }
        )
    }
}

@objc fileprivate final class ResourceWrapper: NSObject {
    var resource = JMTimelineResource.failure()
    init(resource: JMTimelineResource) { self.resource = resource }
}
