//  
//  ChatModuleAssembly.swift
//  Pods
//
//  Created by Stan Potemkin on 11.08.2022.
//

import Foundation
import JMTimelineKit

typealias ChatModulePipeline = RTEModulePipeline<
    ChatModuleCoreEvent,
    ChatModulePresenterUpdate,
    ChatModuleViewIntent,
    ChatModuleJointInput,
    ChatModuleView
>

typealias ChatModule = RTEModule<
    ChatModulePresenterUpdate,
    ChatModuleViewIntent,
    ChatModuleJoint,
    ChatModuleView
>

final class ChatModuleBuilder: RTNavigatorDestination<ChatModule> {
    init(uiConfig: ChatModuleUIConfig, closeButton: JVDisplayCloseButton, reducer: @escaping Reducer<ChatModuleJointOutput>) {
        super.init { engine, navigator, callback in
            let module = ChatModuleAssembly(
                engine: engine,
                navigator: navigator,
                uiConfig: uiConfig,
                closeButton: closeButton
            )
            
            module.joint.attach { output in
                callback(reducer(output))
            }
            
            return (module, module.view)
        }
    }
}

enum ChatModuleWrappingKind {
    case viewController
    case navigationController
}

func ChatModuleAssembly(engine: RTEConfigTrunk, navigator: IRTNavigator, uiConfig: ChatModuleUIConfig, closeButton: JVDisplayCloseButton) -> ChatModule {
    let keyboardAnchorControl = KeyboardAnchorControl()
    
    let timelineProvider = ChatTimelineProvider(
        client: nil,
        formattingProvider: engine.providers.formattingProvider,
        remoteStorageService: engine.services.remoteStorageService,
        mentionProvider: engine.providers.mentionRetriever
    )
    
    let timelineInteractor = ChatTimelineInteractor(
        clientManager: engine.managers.clientManager,
        chatManager: engine.managers.chatManager,
        remoteStorageService: engine.services.remoteStorageService,
        popupPresenterBridge: engine.bridges.popupPresenterBridge,
        databaseDriver: engine.drivers.databaseDriver
    )
    
    let timelineFactory = ChatTimelineFactory(
        userContext: engine.clientContext,
        databaseDriver: engine.drivers.databaseDriver,
        systemMessagingService: engine.services.systemMessagingService,
        provider: timelineProvider,
        interactor: timelineInteractor,
        isGroup: false,
        disablingOptions: [.clientUserpic],
        botStyle: .outer,
        displayNameKind: .original,
        outcomingPalette: uiConfig.outcomingPalette,
        keyboardAnchorControl: keyboardAnchorControl,
        contactFormCache: engine.retrieveCacheBundle(token: engine.clientContext.personalNamespace).contactFormCache,
        historyDelegate: nil
    )
    
    let timelineController = JMTimelineController<ChatTimelineInteractor>(
        factory: timelineFactory,
        cache: engine.timelineCache,
        maxImageDiskCacheSize: 50 * 1024 * 1024
    )

    return RTEModuleAssembly(
        pipeline: ChatModulePipeline(),
        state: ChatModuleState(
            uiConfig: uiConfig,
            authorizationState: engine.clientContext.authorizationState
        ),
        coreBuilder: { pipeline, state in
            ChatModuleCore(
                pipeline: pipeline,
                state: state,
                workerThread: engine.threads.workerThread,
                managerPipeline: engine.managers.pipeline,
                sessionContext: engine.sessionContext,
                clientContext: engine.clientContext,
                messagingContext: engine.messagingContext,
                sessionManager: engine.managers.sessionManager,
                chatManager: engine.managers.chatManager,
                typingCacheService: engine.services.typingCacheService,
                remoteStorageService: engine.services.remoteStorageService,
                systemMessagingService: engine.services.systemMessagingService,
                chatCacheService: engine.services.chatCacheService,
                mediaRequestService: engine.services.mediaRequestService,
                apnsService: engine.services.apnsService,
                popupPresenterBridge: engine.bridges.popupPresenterBridge,
                networking: engine.networking,
                formattingProvider: engine.providers.formattingProvider,
                databaseDriver: engine.drivers.databaseDriver,
                mentionRetriever: engine.providers.mentionRetriever,
                timelineFactory: timelineFactory,
                timelineController: timelineController,
                timelineInteractor: timelineInteractor,
                timelineCache: engine.timelineCache,
                uiConfig: uiConfig,
                maxImageDiskCacheSize: 15 * 1024 * 1024
            )
        },
        presenterBuilder: { pipeline, state in
            ChatModulePresenter(
                pipeline: pipeline,
                state: state
            )
        },
        viewBuilder: { pipeline in
            ChatModuleView(
                pipeline: pipeline,
                keyboardAnchorControl: keyboardAnchorControl,
                timelineController: timelineController,
                timelineInteractor: timelineInteractor,
                uiConfig: uiConfig,
                closeButton: closeButton
            )
        },
        jointBuilder: { pipeline, state, view in
            ChatModuleJoint(
                pipeline: pipeline,
                state: state,
                view: view,
                navigator: navigator,
                uiConfig: uiConfig,
                typingCacheService: engine.services.typingCacheService,
                popupPresenterBridge: engine.bridges.popupPresenterBridge,
                photoPickingBridge: engine.bridges.photoPickingBridge,
                documentsBridge: engine.bridges.documentsBridge,
                webBrowsingBridge: engine.bridges.webBrowsingBridge,
                emailComposingBridge: engine.bridges.emailComposingBridge,
                photoLibraryDriver: engine.drivers.photoLibraryDriver,
                cameraDriver: engine.drivers.cameraDriver
            )
        })
}
