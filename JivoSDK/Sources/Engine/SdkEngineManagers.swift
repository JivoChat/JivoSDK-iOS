//
//  SdkEngineManagers.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 16.02.2021.
//

import Foundation


struct SdkEngineManagers {
    let pipeline: SdkManagerPipeline
    let sessionManager: ISdkSessionManager
    let clientManager: ISdkClientManager
    let chatManager: ISdkChatManager
    
    func notify(event: SdkManagerPipelineEvent) {
        pipeline.notify(event: event)
    }
}

struct SdkEngineManagersFactory {
    let apnsEnvironment: UIApplication.ApnsEnvironment
    
    let workerThread: JVIDispatchThread
    let uploadingQueue: DispatchQueue
    let sessionContext: ISdkSessionContext
    let clientContext: ISdkClientContext
    let messagingContext: ISdkMessagingContext
    let networkEventDispatcher: INetworkingEventDispatcher
    let uuidProvider: IUUIDProvider
    
    let networking: INetworking
    let networkingHelper: INetworkingHelper
    let systemMessagingService: ISystemMessagingService
    let typingCacheService: ITypingCacheService
    let remoteStorageService: IRemoteStorageService
    let apnsService: ISdkApnsService
    
    let localeProvider: JVILocaleProvider
    let pushCredentialsRepository: PushCredentialsRepository
    let preferencesDriver: IPreferencesDriver
    let keychainDriver: IKeychainDriver
    let reachabilityDriver: IReachabilityDriver
    let databaseDriver: JVIDatabaseDriver
    let schedulingDriver: ISchedulingDriver
    let cacheDriver: ICacheDriver
    
    func build() -> SdkEngineManagers {
        let pipeline = SdkManagerPipeline(
            workerThread: workerThread
        )
        
        let managers = SdkEngineManagers(
            pipeline: pipeline,
            sessionManager: buildSessionManager(pipeline: pipeline),
            clientManager: buildClientManager(pipeline: pipeline),
            chatManager: buildChatManager(pipeline: pipeline)
        )
        
        managers.sessionManager.subscribe()
        managers.clientManager.subscribe()
        managers.chatManager.subscribe()

        managers.sessionManager.run()
        managers.clientManager.run()
        managers.chatManager.run()
        
        return managers
    }
    
    private func buildSessionManager(pipeline: SdkManagerPipeline) -> ISdkSessionManager {
        let sessionProto = SdkSessionProto(
            clientContext: clientContext,
            socketUUID: UUID(),
            networking: networking,
            networkingHelper: networkingHelper,
            keychainTokenAccessor: keychainDriver.retrieveAccessor(forToken: .token),
            uuidProvider: uuidProvider,
            localeProvider: localeProvider
        )

        let sessionManager = SdkSessionManager(
            pipeline: pipeline,
            thread: workerThread,
            proto: sessionProto,
            sessionContext: sessionContext,
            clientContext: clientContext,
            messagingContext: messagingContext,
            networking: networking,
            subStorage: SdkSessionSubStorage(
                clientContext: clientContext,
                databaseDriver: databaseDriver
            ),
            networkEventDispatcher: networkEventDispatcher,
            apnsService: apnsService,
            preferencesDriver: preferencesDriver,
            keychainDriver: keychainDriver,
            reachabilityDriver: reachabilityDriver,
            uuidProvider: uuidProvider
        )

        return sessionManager
    }
    
    private func buildClientManager(pipeline: SdkManagerPipeline) -> ISdkClientManager {
        let clientProto = SdkClientProto(
            userContext: clientContext,
            socketUUID: UUID(),
            networking: networking,
            networkingHelper: networkingHelper,
            keychainTokenAccessor: keychainDriver.retrieveAccessor(forToken: .token),
            uuidProvider: uuidProvider
        )
        
        let subPusher = SdkClientSubPusher(
            apnsEnvironment: apnsEnvironment,
            pushCredentialsRepository: pushCredentialsRepository,
            proto: clientProto,
            throttlingQueue: ThrottlingQueue(queue: .main, delay: 2)
        )

        networkEventDispatcher.register(decoder: nil, handler: subPusher)
        
        let clientManager = SdkClientManager(
            pipeline: pipeline,
            thread: workerThread,
            subPusher: subPusher,
            sessionContext: sessionContext,
            clientContext: clientContext,
            proto: clientProto,
            networkEventDispatcher: networkEventDispatcher,
            uuidProvider: uuidProvider,
            preferencesDriver: preferencesDriver,
            keychainDriver: keychainDriver
        )
        
        return clientManager
    }
    
    private func buildChatManager(pipeline: SdkManagerPipeline) -> ISdkChatManager {
        let chatProto = SdkChatProto(
            userContext: clientContext,
            socketUUID: UUID(),
            networking: networking,
            networkingHelper: networkingHelper,
            keychainTokenAccessor: keychainDriver.retrieveAccessor(forToken: .token),
            uuidProvider: uuidProvider
        )
        
        let chatEventObservable = JVBroadcastTool<SdkChatEvent>()

        let chatContext = SdkChatContext()
        
        let chatSubStorage = SdkChatSubStorage(
            sessionContext: sessionContext,
            clientContext: clientContext,
            databaseDriver: databaseDriver,
            keychainDriver: keychainDriver,
            systemMessagingService: systemMessagingService
        )
        
        let subTyping = SdkChatSubLivetyping(
            proto: chatProto,
            timeoutBoxService: schedulingDriver
        )
        
        let chatSubSender = SdkChatSubSender(
            clientContext: clientContext,
            messagingContext: messagingContext,
            databaseDriver: databaseDriver,
            proto: chatProto,
            subStorage: chatSubStorage,
            systemMessagingService: systemMessagingService,
            scheduledActionTool: schedulingDriver
        )
        
        let chatSubUploader = SdkChatSubUploader(
            uploadingQueue: uploadingQueue,
            workerThread: workerThread,
            remoteStorageService: remoteStorageService
        )
        
        let chatSubOfflineStateFeature = SdkChatSubOffline(
            databaseDriver: databaseDriver,
            preferencesDriver: preferencesDriver,
            chatEventObservable: chatEventObservable,
            messagingEventObservable: messagingContext.eventObservable,
            chatContext: chatContext,
            chatSubStorage: chatSubStorage
        )
        
        let chatSubHelloStateFeature = SdkChatSubHello(
            databaseDriver: databaseDriver,
            preferencesDriver: preferencesDriver,
            messagingEventObservable: messagingContext.eventObservable,
            chatContext: chatContext,
            chatSubStorage: chatSubStorage
        )
        
        let chatManager = SdkChatManager(
            pipeline: pipeline,
            thread: workerThread,
            sessionContext: sessionContext,
            clientContext: clientContext,
            messagingContext: messagingContext,
            proto: chatProto,
            eventObservable: chatEventObservable,
            chatContext: chatContext,
            chatSubStorage: chatSubStorage,
            subTyping: subTyping,
            chatSubSender: chatSubSender,
            subUploader: chatSubUploader,
            subOfflineStateFeature: chatSubOfflineStateFeature,
            subHelloStateFeature: chatSubHelloStateFeature,
            systemMessagingService: systemMessagingService,
            networkEventDispatcher: networkEventDispatcher,
            typingCacheService: typingCacheService,
            apnsService: apnsService,
            preferencesDriver: preferencesDriver,
            keychainDriver: keychainDriver
        )
        
        return chatManager
    }
}
