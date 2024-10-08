//
//  SdkEngineServices.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 23.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import JMCodingKit
import SwiftMime

struct SdkEngineServices {
    let systemMessagingService: ISystemMessagingService
    let chatCacheService: IChatCacheService
    let mediaRequestService: IMediaRequestService
    let typingCacheService: ITypingCacheService
    let workflowsService: IWorkflowsService
    let remoteStorageService: IRemoteStorageService
    let apnsService: ISdkApnsService
}

struct SdkEngineServicesFactory {
    let sessionContext: ISdkSessionContext
    let clientContext: ISdkClientContext
    let workerThread: JVIDispatchThread
    let networking: INetworking
    let networkingHelper: INetworkingHelper
    let networkingEventDispatcher: INetworkingEventDispatcher
    let drivers: SdkEngineDrivers
    let providers: SdkEngineProviders
    
    func build() -> SdkEngineServices {
        return SdkEngineServices(
            systemMessagingService: buildSystemMessagingService(workerThread: workerThread),
            chatCacheService: buildChatCacheService(),
            mediaRequestService: buildMediaRequestService(),
            typingCacheService: buildTypingCacheService(),
            workflowsService: buildWorkflowsService(),
            remoteStorageService: buildRemoteStorageService(),
            apnsService: buildSdkApnsService()
        )
    }
    
    private func buildSystemMessagingService(workerThread: JVIDispatchThread) -> ISystemMessagingService {
        return SystemMessagingService(
            thread: workerThread,
            databaseDriver: drivers.databaseDriver,
            formattingProvider: providers.formattingProvider)
    }
    
    private func buildChatCacheService() -> IChatCacheService {
        return ChatCacheService()
    }
    
    private func buildMediaRequestService() -> IMediaRequestService {
        return MediaRequestService(photoLibraryDriver: drivers.photoLibraryDriver)
    }
    
    private func buildTypingCacheService() -> ITypingCacheService {
        return TypingCacheService(
            fileURL: drivers.cacheDriver.url(item: .typingCache) ?? URL(fileURLWithPath: "/tmp/typing_cache.plist"),
            attachmentsNumberLimit: SdkConfig.attachmentsNumberLimit,
            agentsRepo: AgentsRepo(
                databaseDriver: drivers.databaseDriver
            ),
            chatsRepo: ChatsRepo(
                databaseDriver: drivers.databaseDriver
            ))
    }
    
    private func buildWorkflowsService() -> IWorkflowsService {
        return WorkflowsService()
    }
    
    private func buildRemoteStorageService() -> IRemoteStorageService {
        return RemoteStorageService(
            thread: workerThread,
            userContext: clientContext,
            networking: networking,
            networkingHelper: networkingHelper,
            networkEventDispatcher: networkingEventDispatcher,
            cacheDriver: drivers.cacheDriver,
            keychainDriver: drivers.keychainDriver,
            centerProvider: { purpose in
                guard let identity = sessionContext.accountConfig,
                      identity.siteId > 0
                else {
                    journal {"Missing credentials for File Upload"}
                    return nil
                }
                
                switch purpose {
                case .exchange:
                    return RemoteStorageCenter(
                        engine: .media,
                        path: "api/1.0/auth/media/sign/put",
                        auth: .omit
                    )
                default:
                    journal {"Unknown purpose for File Upload"}
                    return nil
                }
            },
            tokenProvider: {
                return nil
            },
            urlBuilder: { standardURL, endpoint, scope, path -> URL? in
                return nil
            }
        )
    }
    
    private func buildSdkApnsService() -> ISdkApnsService {
        return SdkApnsService(apnsDriver: drivers.apnsDriver)
    }
    
//    private func buildCloudStorageService() -> ICloudStorageService {
//        let standartCloudStorageService = CloudStorageServiceFactory.standart(apiHostProvider: {
//            return clientContext.connectionConfig?.apiHost ?? String()
//        })
//        .build()
//
//        return standartCloudStorageService
//    }
}

protocol INetworkServiceFactory {
    func build() -> INetworking
}

struct NetworkServiceFactory: INetworkServiceFactory {
    let workerThread: JVIDispatchThread
    let networkingHelper: INetworkingHelper
    let socketDriver: ILiveConnectionDriver
    let restConnectionDriver: IRestConnectionDriver
    let localeProvider: JVILocaleProvider
    let uuidProvider: IUUIDProvider
    let preferencesDriver: IPreferencesDriver
    let keychainDriver: IKeychainDriver
    let jsonPrivacyTool: JVJsonPrivacyTool
    let urlBuilder: NetworkingUrlBuilder
    
    func build() -> INetworking {
        let networkSubSocket = NetworkingSubSocket(
            namespace: "jivosdk",
            identifier: UUID(),
            driver: socketDriver,
            networkingThread: workerThread,
            behavior: .json,
            jsonPrivacyTool: jsonPrivacyTool
        )
        
        let networkSubRest = NetworkingSubRest(
            networkingHelper: networkingHelper,
            driver: restConnectionDriver
        )
        
        return Networking(
            defaultHost: nil,
            subSocket: networkSubSocket,
            subRest: networkSubRest,
            subApns: nil,
            localeProvider: localeProvider,
            uuidProvider: uuidProvider,
            preferencesDriver: preferencesDriver,
            keychainDriver: keychainDriver,
            jsonPrivacyTool: jsonPrivacyTool,
            urlBuilder: urlBuilder
        )
    }
}

//protocol IRemoteStorageServiceFactory {
//    func build() -> IRemoteStorageService
//}
//
//enum RemoteStorageServiceFactory {
//    case standard(apiHostProvider: () -> String)
//}
//
//extension RemoteStorageServiceFactory: IRemoteStorageServiceFactory {
//    func build() -> IRemoteStorageService {
//        switch self {
//        case let .standard(apiHostProvider):
//            return buildStandard(apiHostProvider: apiHostProvider)
//        }
//    }
//
//    private func buildStandard(apiHostProvider: @escaping () -> String) -> RemoteStorageService {
//        let service = RemoteStorageService(
//            tokenProvider: { nil },
//            apiHostProvider: apiHostProvider
//        )
//        return service
//    }
//}

fileprivate extension URL {
    var normalizedExtension: String? {
        return lastPathComponent.jv_fileExtension?.lowercased()
    }
}
