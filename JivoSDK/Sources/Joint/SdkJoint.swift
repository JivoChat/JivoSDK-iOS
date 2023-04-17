//
//  SdkJoint.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 21.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import UIKit
#if canImport(JivoFoundation)
import JivoFoundation
#endif
import BABFrameObservingInputAccessoryView
import JMTimelineKit

protocol ISdkJoint {
    var isDisplaying: Bool { get }
    func modifyConfig(block: (inout SdkInputConfig) -> Void)
    func push(into navigationController: UINavigationController, displayDelegate: JVDisplayDelegate?)
    func place(within navigationController: UINavigationController, closeButton: JVDisplayCloseButton, displayDelegate: JVDisplayDelegate?)
    func present(over viewController: UIViewController, displayDelegate: JVDisplayDelegate?)
}

struct SdkInputConfig {
    var locale: Locale?
    var extraMenuItems = [JVDisplayMenu: [String]]()
    var extraMenuHandlers = [JVDisplayMenu: (Int) -> Void]()
}

class SdkJoint: ISdkJoint {
    private let engine: ISdkEngine
    
    private let navigator: IRTNavigator
    private var config = SdkInputConfig()
    private lazy var uiConfig = buildChatModuleUIConfig(from: SdkInputConfig(), displayDelegate: nil)
    private weak var rootViewController: UIViewController?
    private weak var chatModuleJoint: ChatModuleJoint?
    private var navigationBarSnapshot: UINavigationController.BarSnapshot?
    private var tabBarSnapshot: UITabBarController.BarSnapshot?

    init(engine: ISdkEngine) {
        self.engine = engine
        
        navigator = RTNavigator(engine: engine)
    }
    
    var isDisplaying: Bool {
        return chatModuleJoint?.view != nil
    }

    func modifyConfig(block: (inout SdkInputConfig) -> Void) {
        block(&config)
    }
    
    func push(into navigationController: UINavigationController, displayDelegate: JVDisplayDelegate?) {
        adjustUI(displayDelegate: displayDelegate)
        
        let module = navigator.push(into: .native(navigationController), animate: true) {
            ChatModuleBuilder(
                uiConfig: uiConfig,
                closeButton: .back,
                reducer: generateReducer(displayDelegate: displayDelegate) { [weak self] in
                    if let snapshot = self?.navigationBarSnapshot {
                        navigationController.restoreBarConfiguration(snapshot: snapshot)
                    }
                }
            )
        }
    
        navigationBarSnapshot = navigationController.configureBar()
        displayDelegate.jv_customizeHeader(
            navigationBar: navigationController.navigationBar,
            navigationItem: module.view.navigationItem)

        if let recognizer = navigationController.interactivePopGestureRecognizer {
            recognizer.delegate = nil
        }
        
        DispatchQueue.main.async { [unowned self] in
            engine.bridges.popupPresenterBridge.take(window: navigationController.view.window)
        }
        
        rootViewController = navigationController
        chatModuleJoint = module.joint
    }
    
    func place(within navigationController: UINavigationController, closeButton: JVDisplayCloseButton, displayDelegate: JVDisplayDelegate?) {
        adjustUI(displayDelegate: displayDelegate)
        
        let module = navigator.replace(inside: .native(navigationController)) {
            ChatModuleBuilder(
                uiConfig: uiConfig,
                closeButton: closeButton,
                reducer: generateReducer(displayDelegate: displayDelegate, dismissalHandler: nil)
            )
        }
        
        //        navigationController.configureTabBarItem()
        navigationController.configureModality()
        displayDelegate.jv_customizeHeader(
            navigationBar: navigationController.navigationBar,
            navigationItem: module.view.navigationItem)
        
        DispatchQueue.main.async { [unowned self] in
//            if let tabBarController = navigationController.tabBarController {
//                self.tabBarSnapshot = tabBarController.configureBar()
//            }
            
            engine.bridges.popupPresenterBridge.take(window: navigationController.view.window)
        }
        
        rootViewController = navigationController
        chatModuleJoint = module.joint
    }
    
    func present(over viewController: UIViewController, displayDelegate: JVDisplayDelegate?) {
        adjustUI(displayDelegate: displayDelegate)
        
        let built = navigator.build {
            ChatModuleBuilder(
                uiConfig: uiConfig,
                closeButton: .dismiss,
                reducer: generateReducer(displayDelegate: displayDelegate, dismissalHandler: nil)
            )
        }
        
        let container = JVNavigationController(rootViewController: built.view)
        container.configureModality()
        displayDelegate.jv_customizeHeader(
            navigationBar: container.navigationBar,
            navigationItem: built.view.navigationItem)
        
        navigationBarSnapshot = container.configureBar()
        viewController.present(container, animated: true, completion: nil)

        DispatchQueue.main.async { [unowned self] in
            engine.bridges.popupPresenterBridge.take(window: viewController.view.window)
        }
        
        rootViewController = container
        chatModuleJoint = built.module.joint
    }
    
    private func adjustUI(displayDelegate: JVDisplayDelegate?) {
        uiConfig = buildChatModuleUIConfig(from: config, displayDelegate: displayDelegate)
        engine.managers.chatManager.subOffline.customText = uiConfig.offlineMessage.jv_valuable
        engine.providers.localeProvider.activeLocale = config.locale ?? .autoupdatingCurrent
    }
    
    private func buildChatModuleUIConfig(from config: SdkInputConfig, displayDelegate: JVDisplayDelegate?) -> ChatModuleUIConfig {
        return ChatModuleUIConfig(
            icon: displayDelegate.jv_defineImage(
                forElement: .headerIcon,
                fallback: JVDesign.icons.find(asset: .agentAvatarIcon, rendering: .original).jv_orEmpty),
            titleCaption: displayDelegate.jv_defineText(
                forElement: .headerTitle,
                fallback: loc["chat_title_placeholder"]),
            titleColor: displayDelegate.jv_defineColor(
                forElement: .headerTitle,
                fallback: .dynamicTitle),
            subtitleCaption: displayDelegate.jv_defineText(
                forElement: .headerSubtitle,
                fallback: loc["chat_subtitle_placeholder"]),
            subtitleColor: displayDelegate.jv_defineColor(
                forElement: .headerSubtitle,
                fallback: .dynamicSubtitle),
            inputPlaceholder: displayDelegate.jv_defineText(
                forElement: .replyPlaceholder,
                fallback: loc["input_message_placeholder"]),
            inputPrefill: displayDelegate.jv_defineText(
                forElement: .replyPrefill,
                fallback: String()),
            helloMessage: displayDelegate.jv_defineText(
                forElement: .messageHello,
                fallback: String()),
            offlineMessage: displayDelegate.jv_defineText(
                forElement: .messageOffline,
                fallback: loc["offline_message_placeholder"]),
            attachCamera: displayDelegate.jv_defineText(
                forElement: .attachCamera,
                fallback: loc["Media.Picker.Camera"]),
            attachLibrary: displayDelegate.jv_defineText(
                forElement: .attachLibrary,
                fallback: loc["media_upload_attachment_type_selecting_photo"]),
            attachFile: displayDelegate.jv_defineText(
                forElement: .attachFile,
                fallback: loc["media_upload_attachment_type_selecting_document"]),
            outcomingPalette: ChatTimelinePalette(
                backgroundColor: displayDelegate.jv_defineColor(
                    forElement: .outgoingElements,
                    fallback: JVDesign.colors.resolve(usage: .accentGreen)),
                foregroundColor: .white,
                buttonsTintColor: displayDelegate.jv_defineColor(
                    forElement: .outgoingElements,
                    fallback: JVDesign.colors.resolve(usage: .accentGreen)),
                inputTintColor: displayDelegate.jv_defineColor(
                    forElement: .outgoingElements,
                    fallback: JVDesign.colors.resolve(usage: .accentGreen))
            ),
            replyMenuExtraItems: config.extraMenuItems[.attach, default: Array()],
            replyMenuCustomHandler: { index in
                config.extraMenuHandlers[.attach]?(index)
            }
        )
    }
    
    private func generateReducer(displayDelegate: JVDisplayDelegate?, dismissalHandler: (() -> Void)?) -> RTNavigatorDestination<ChatModule>.Reducer<ChatModuleJointOutput> {
        return { [weak displayDelegate] output in
            switch output {
            case .started:
                displayDelegate?.jivoDisplay(willAppear: .shared)
            case .finished:
                displayDelegate?.jivoDisplay(didDisappear: .shared)
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

fileprivate extension Optional where Wrapped == JVDisplayDelegate {
    func jv_customizeHeader(navigationBar: UINavigationBar, navigationItem: UINavigationItem) {
        if let _ = self?.jivoDisplay?(customizeHeader: .shared, navigationBar: navigationBar, navigationItem: navigationItem) {
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
    
    func jv_defineText(forElement element: JVDisplayElement, fallback: String) -> String {
        return self?.jivoDisplay?(defineText: .shared, forElement: element) ?? fallback
    }
    
    func jv_defineColor(forElement element: JVDisplayElement, fallback: UIColor) -> UIColor {
        return self?.jivoDisplay?(defineColor: .shared, forElement: element) ?? fallback
    }
    
    func jv_defineImage(forElement element: JVDisplayElement, fallback: UIImage) -> UIImage {
        return self?.jivoDisplay?(defineImage: .shared, forElement: element) ?? fallback
    }
}
