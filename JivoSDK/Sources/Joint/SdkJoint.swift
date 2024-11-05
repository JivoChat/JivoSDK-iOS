//
//  SdkJoint.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 21.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import UIKit
import JMTimelineKit

#if canImport(SwiftUI)
import SwiftUI
#endif

protocol ISdkJoint {
    var isDisplaying: Bool { get }
    func modifyConfig(block: (inout SdkInputConfig) -> Void)
    func push(into navigationController: UINavigationController, displayCallbacks: JVDisplayCallbacks?) -> JVSessionHandle
    func place(within navigationController: UINavigationController, closeButton: JVDisplayCloseButton, displayCallbacks: JVDisplayCallbacks?) -> JVSessionHandle
    func present(over viewController: UIViewController, displayCallbacks: JVDisplayCallbacks?) -> JVSessionHandle
    func close(animated: Bool)
    
    #if canImport(SwiftUI)
    @available(iOS 13.0, *)
    func makeScreen(presentation: JVDisplayScreenPresentation, displayCallbacks: JVDisplayCallbacks?) -> JVDisplayWrapper
    #endif
}

struct SdkInputConfig {
    var locale: Locale?
    var customizationTextMapping = [JVDisplayElement: String]()
    var customizationColorMapping = [JVDisplayElement: UIColor]()
    var customizationImageMapping = [JVDisplayElement: UIImage]()
    var extraMenuItems = [JVDisplayMenu: [String]]()
    var extraMenuHandlers = [JVDisplayMenu: (Int) -> Void]()
}

class SdkJoint: ISdkJoint {
    private let engine: ISdkEngine
    
    private let navigator: IRTNavigator
    private var config = SdkInputConfig()
    private lazy var uiConfig = buildChatModuleVisualConfig(from: SdkInputConfig(), displayCallbacks: nil)
    private weak var chatModuleJoint: ChatModuleJoint?
    private var navigationBarSnapshot: UINavigationController.BarSnapshot?
    private var tabBarSnapshot: UITabBarController.BarSnapshot?

    init(engine: ISdkEngine) {
        self.engine = engine
        
        navigator = RTNavigator(engine: engine)
    }
    
    var isDisplaying: Bool {
        guard let canvas = chatModuleJoint?.view else {
            return false
        }
        
        if let container = canvas.navigationController?.tabBarController {
            let result = not(container.view.window == nil)
            return result
        }
        else if let navigationController = canvas.navigationController {
            if navigationController.viewControllers.first === canvas {
                let result = not(navigationController.presentingViewController == nil)
                return result
            }
            else {
                return true
            }
        }
        else {
            return false
        }
    }

    func modifyConfig(block: (inout SdkInputConfig) -> Void) {
        block(&config)
    }
    
    func push(into navigationController: UINavigationController, displayCallbacks: JVDisplayCallbacks?) -> JVSessionHandle {
        let reducer = generateReducer(displayCallbacks: displayCallbacks) { [weak self] in
            if let snapshot = self?.navigationBarSnapshot {
                navigationController.restoreBarConfiguration(snapshot: snapshot)
            }
        }
        
        let module = navigator.push(into: .native(navigationController), animate: true) {
            adjustUI(displayCallbacks: displayCallbacks)
            return ChatModuleBuilder(
                uiConfig: uiConfig,
                timelineConfig: makeTimelineConfig(input: config, displayCallbacks: displayCallbacks),
                closeButton: .back,
                reducer: reducer
            )
        }
    
        navigationBarSnapshot = navigationController.configureBar()
        displayCallbacks.jv_customizeHeader(
            navigationBar: navigationController.navigationBar,
            navigationItem: module.view.navigationItem)

        if let recognizer = navigationController.interactivePopGestureRecognizer {
            recognizer.delegate = nil
        }
        
        chatModuleJoint = module.joint
        DispatchQueue.main.async { [unowned self] in
            engine.bridges.popupPresenterBridge.take(window: navigationController.view.window)
        }
        
        return prepareTemporarySessionHandle()
    }
    
    func place(within navigationController: UINavigationController, closeButton: JVDisplayCloseButton, displayCallbacks: JVDisplayCallbacks?) -> JVSessionHandle {
        let reducer = generateReducer(displayCallbacks: displayCallbacks) {
            // dismissal
        }
        
        let module = navigator.replace(inside: .native(navigationController)) {
            adjustUI(displayCallbacks: displayCallbacks)
            return ChatModuleBuilder(
                uiConfig: uiConfig,
                timelineConfig: makeTimelineConfig(input: config, displayCallbacks: displayCallbacks),
                closeButton: closeButton,
                reducer: reducer
            )
        }
        
        //        navigationController.configureTabBarItem()
        navigationController.configureModality()
        displayCallbacks.jv_customizeHeader(
            navigationBar: navigationController.navigationBar,
            navigationItem: module.view.navigationItem)
        
        chatModuleJoint = module.joint
        DispatchQueue.main.async { [unowned self] in
            engine.bridges.popupPresenterBridge.take(window: navigationController.view.window)
        }
        
        return prepareTemporarySessionHandle()
    }
    
    func present(over viewController: UIViewController, displayCallbacks: JVDisplayCallbacks?) -> JVSessionHandle {
        let reducer = generateReducer(displayCallbacks: displayCallbacks) {
            // dismissal
        }
        
        let built = navigator.build {
            adjustUI(displayCallbacks: displayCallbacks)
            return ChatModuleBuilder(
                uiConfig: uiConfig,
                timelineConfig: makeTimelineConfig(input: config, displayCallbacks: displayCallbacks),
                closeButton: .dismiss,
                reducer: reducer
            )
        }
        
        let container = JVNavigationContainer(rootViewController: built.view)
        container.configureModality()
        displayCallbacks.jv_customizeHeader(
            navigationBar: container.navigationBar,
            navigationItem: built.view.navigationItem)
        
        navigationBarSnapshot = container.configureBar()
        viewController.present(container, animated: true, completion: nil)

        chatModuleJoint = built.module.joint
        DispatchQueue.main.async { [unowned self] in
            engine.bridges.popupPresenterBridge.take(window: viewController.view.window)
        }
        
        return prepareTemporarySessionHandle()
    }
    
    #if canImport(SwiftUI)
    @available(iOS 13.0, *)
    func makeScreen(presentation: JVDisplayScreenPresentation, displayCallbacks: JVDisplayCallbacks?) -> JVDisplayWrapper {
        let reducer = generateReducer(displayCallbacks: displayCallbacks) {
            // dismissal
        }
        
        let closeButton: JVDisplayCloseButton = switch presentation {
            case .modal: .dismiss
        }
        
        let built = navigator.build {
            adjustUI(displayCallbacks: displayCallbacks)
            return ChatModuleBuilder(
                uiConfig: uiConfig,
                timelineConfig: makeTimelineConfig(input: config, displayCallbacks: displayCallbacks),
                closeButton: closeButton,
                reducer: reducer
            )
        }
        
        let container = JVNavigationContainer(rootViewController: built.view)
        container.configureModality()
        displayCallbacks.jv_customizeHeader(
            navigationBar: container.navigationBar,
            navigationItem: built.view.navigationItem)
        
        navigationBarSnapshot = container.configureBar()

        chatModuleJoint = built.module.joint
        DispatchQueue.main.async { [unowned self] in
            engine.bridges.popupPresenterBridge.take(window: container.view.window)
        }
        
        switch presentation {
        case .modal:
            _ = prepareTemporarySessionHandle()
            return JVDisplayWrapper(viewController: container)
        }
    }
    #endif
    
    func close(animated: Bool) {
        guard let content = chatModuleJoint?.view else {
            return
        }
        
        if let container = content.presentingViewController {
            container.dismiss(animated: animated)
        }
        else if let navigationController = content.navigationController {
            navigationController.popViewController(animated: animated)
        }
    }
    
    private func adjustUI(displayCallbacks: JVDisplayCallbacks?) {
        engine.providers.localeProvider.activeLocale = config.locale ?? .autoupdatingCurrent
        uiConfig = buildChatModuleVisualConfig(from: config, displayCallbacks: displayCallbacks)
        engine.managers.chatManager.subOffline.customText = uiConfig.offlineMessage.jv_valuable
        engine.managers.chatManager.subHello.customText = uiConfig.helloMessage.jv_valuable
    }
    
    private func prepareTemporarySessionHandle() -> JVSessionHandle {
        let sessionHandle = JVSessionHandle()
        engine.managers.chatManager.activeSessionHandle = sessionHandle
        
        DispatchQueue.main.async {
            sessionHandle.disableInteraction()
        }
        
        return sessionHandle
    }
    
    private func buildChatModuleVisualConfig(from config: SdkInputConfig, displayCallbacks: JVDisplayCallbacks?) -> SdkChatModuleVisualConfig {
        return SdkChatModuleVisualConfig(
            icon: config.customizationImageMapping[
                .headerIcon,
                default: JVDesign.icons.find(asset: .agentAvatarIcon, rendering: .original).jv_orEmpty
            ],
            titleCaption: config.customizationTextMapping[
                .headerTitle,
                default: loc["JV_ChatNavigation_HeaderTitle_Default", "chat_title_placeholder"]
            ],
            titleColor: config.customizationColorMapping[
                .headerTitle,
                default: .dynamicTitle
            ],
            subtitleCaption: config.customizationTextMapping[
                .headerSubtitle,
                default: loc["JV_ChatNavigation_HeaderSubtitle_Default", "chat_subtitle_placeholder"]
            ],
            subtitleColor: config.customizationColorMapping[
                .headerSubtitle,
                default: .dynamicSubtitle
            ],
            inputPlaceholder: config.customizationTextMapping[
                .replyPlaceholder,
                default: loc["JV_ChatInput_Message_Placeholder", "input_message_placeholder"]
            ],
            inputPrefill: config.customizationTextMapping[
                .replyPrefill,
                default: .jv_empty
            ],
            helloMessage: config.customizationTextMapping[
                .messageWelcome,
                default: .jv_empty
            ],
            offlineMessage: config.customizationTextMapping[
                .messageOffline,
                default: loc["JV_ChatTimeline_SystemMessage_OfflineDefault", "offline_message_placeholder"]
            ],
            attachCamera: config.customizationTextMapping[
                .attachCamera,
                default: loc["JV_ChatInput_MenuAttach_Camera", "Media.Picker.Camera"]
            ],
            attachLibrary: config.customizationTextMapping[
                .attachLibrary,
                default: loc["JV_ChatInput_MenuAttach_Gallery", "media_upload_attachment_type_selecting_photo"]
            ],
            attachFile: config.customizationTextMapping[
                .attachFile,
                default: loc["JV_ChatInput_MenuAttach_Document", "media_upload_attachment_type_selecting_document"]
            ],
            replyMenuExtraItems: config.extraMenuItems[
                .attach,
                default: .jv_empty
            ],
            replyMenuCustomHandler: { index in
                config.extraMenuHandlers[.attach]?(index)
            },
            replyCursorColor: config.customizationColorMapping[
                .outgoingElements,
                default: JVDesign.colors.resolve(usage: .accentGreen)
            ]
        )
    }
    
    private func makeTimelineConfig(input config: SdkInputConfig, displayCallbacks: JVDisplayCallbacks?) -> ChatTimelineVisualConfig {
        return ChatTimelineVisualConfig(
            outcomingPalette: .init(
                backgroundColor: config.customizationColorMapping[
                    .outgoingElements,
                    default: JVDesign.colors.resolve(usage: .accentGreen)
                ],
                foregroundColor: .white,
                buttonsTintColor: config.customizationColorMapping[
                    .outgoingElements,
                    default: JVDesign.colors.resolve(usage: .accentGreen)
                ]
            ),
            rateForm: .init(
                preSubmitTitle: config.customizationTextMapping[
                    .rateFormPreSubmitTitle,
                    default: loc["JV_RateForm_HeaderTitle_BeforeSubmission", "rate_form.title"]
                ],
                postSubmitTitle: config.customizationTextMapping[
                    .rateFormPostSubmitTitle,
                    default: loc["JV_RateForm_HeaderTitle_AfterSubmission", "rate_form.finish_title"]
                ],
                commentPlaceholder: config.customizationTextMapping[
                    .rateFormCommentPlaceholder,
                    default: loc["JV_RateForm_CommentField_Legend", "rate_form.comment_title"]
                ],
                submitCaption: config.customizationTextMapping[
                    .rateFormSubmitCaption,
                    default: loc["JV_RateForm_SubmitButton_Caption", "rate_form.send"]
                ]
            )
        )
    }
    
    private func generateReducer(displayCallbacks: JVDisplayCallbacks?, dismissalHandler: (() -> Void)?) -> RTNavigatorDestination<ChatModule>.Reducer<ChatModuleJointOutput> {
        displayCallbacks?.willAppearHandler()
        
        return { [weak displayCallbacks] output in
            switch output {
            case .started:
                break
            case .finished:
                displayCallbacks?.didDisappearHandler()
            case .dismiss:
                dismissalHandler?()
            }
            
            return .keep
        }
    }
}

fileprivate extension UIViewController {
    func configureModality() {
        modalPresentationStyle = .fullScreen
        
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
    }
    
    func configureTabBarItem() {
        if #available(iOS 13.0, *) {
            let config = UITabBarAppearance()
            config.configureWithOpaqueBackground()

            tabBarItem.standardAppearance = config
            if #available(iOS 15.0, *) {
                tabBarItem.scrollEdgeAppearance = config
            }
        }
    }
}

fileprivate extension UINavigationController {
    struct BarSnapshot {
        let isTranslucent: Bool
    }
    
    func configureBar() -> BarSnapshot {
        defer {
            navigationBar.isTranslucent = false
        }
        
        return BarSnapshot(
            isTranslucent: navigationBar.isTranslucent
        )
    }
    
    func restoreBarConfiguration(snapshot: BarSnapshot) {
        navigationBar.isTranslucent = snapshot.isTranslucent
    }
}

fileprivate extension UITabBarController {
    struct BarSnapshot {
        let isTranslucent: Bool
    }
    
    func configureBar() -> BarSnapshot {
        defer {
            tabBar.isTranslucent = false
        }
        
        return BarSnapshot(
            isTranslucent: tabBar.isTranslucent
        )
    }
    
    func restoreBarConfiguration(snapshot: BarSnapshot) {
        tabBar.isTranslucent = snapshot.isTranslucent
    }
}

fileprivate extension Optional where Wrapped == JVDisplayCallbacks {
    func jv_customizeHeader(navigationBar: UINavigationBar, navigationItem: UINavigationItem) {
        if let _ = self?.customizeHeaderHandler(navigationBar, navigationItem) {
            return
        }
        else if #available(iOS 13.0, *) {
            let config = UINavigationBarAppearance()
            config.configureWithOpaqueBackground()

            navigationItem.standardAppearance = config
            navigationItem.compactAppearance = config
            navigationItem.scrollEdgeAppearance = config
            
            if #available(iOS 15.0, *) {
                navigationItem.compactScrollEdgeAppearance = config
            }
        }
    }
}

#if canImport(SwiftUI)
@available(iOS 13.0, *)
@_documentation(visibility: internal)
public struct JVDisplayWrapper: UIViewControllerRepresentable {
    let viewController: UIViewController
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    public func makeUIViewController(context: Context) -> UIViewController {
        return viewController
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
#endif
