//
//  PopupPresenterBridge.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 30/06/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit

enum PopupPresenterBehavior {
    case alert
    case actionSheet
}

enum PopupPresenterDisplayContainer {
    case auto
    case root
    case specific(UIViewController?)
}

struct PopupPresenterShortlyOptions: OptionSet {
    let rawValue: Int
    static let template = Self.init(rawValue: 1 << 0)
    static let scale = Self.init(rawValue: 1 << 1)
}

enum PopupPresenterMenuLocation {
    case top
    case bottom
}

final class PopupPresenterBridge: NSObject, IPopupPresenterBridge {
    private weak var window: UIWindow?
    
    let informableContainer: PopupInformingContainer
    
    init(window: UIWindow, alertableContainer: PopupInformingContainer) {
        self.window = window
        self.informableContainer = alertableContainer
        
        super.init()
    }
    
    override init() {
        self.window = nil
        self.informableContainer = PopupInformingContainer()
        
        super.init()
    }
    
    func take(window: UIWindow?) {
        self.window = window
    }
    
    func displayAlert(within container: PopupPresenterDisplayContainer, title: String?, message: String?, items: [PopupPresenterItem]) {
        let alert = constructAlert(title: title, about: message)
        PopupPresenterAlertConfigurator(items: items).configure(alert: alert)
        displayAsModal(within: container, viewController: alert)
    }
    
    func displayMenu(within container: PopupPresenterDisplayContainer, anchor: UIView?, title: String?, message: String?, items: [PopupPresenterItem]) {
        if UIDevice.current.jv_isPhone || anchor.jv_hasValue {
            let alert = constructActionSheet(title: title, about: message, anchor: anchor)
            PopupPresenterAlertConfigurator(items: items).configure(alert: alert)
            displayAsModal(within: container, viewController: alert)
        }
        else {
            let alert = constructAlert(title: title, about: message)
            PopupPresenterAlertConfigurator(items: items).configure(alert: alert)
            displayAsModal(within: container, viewController: alert)
        }
    }
    
    func displayFlexibleMenu(within container: PopupPresenterDisplayContainer, source: FlexibleMenuTriggerButton?, items: [PopupPresenterFlexibleMenuItem]) {
        source?.willDisplayMenuHandler?()
        let viewController = PopupFlexibleMenuViewController()
        viewController.items = items
        viewController.modalPresentationStyle = .popover
        viewController.popoverPresentationController?.delegate = viewController
        viewController.popoverPresentationController?.sourceView = source
        viewController.popoverPresentationController?.permittedArrowDirections = []
        displayAsModal(within: container, viewController: viewController)
    }
    
    func informShortly(message: String) {
        informableContainer.display(
            title: message,
            icon: nil,
            template: false,
            iconMode: .center)
    }
    
    func informShortly(message: String?, icon: UIImage?, options: PopupPresenterShortlyOptions) {
        informableContainer.display(
            title: message,
            icon: icon,
            template: options.contains(.template),
            iconMode: options.contains(.scale) ? .scaleAspectFill : .center)
    }
    
    func attachMenu(to button: UIButton, location: PopupPresenterMenuLocation, items: [PopupPresenterItem]) {
        let gesture = ContextMenuGesture(
            target: self,
            action: #selector(handleContextMenuGesture),
            items: items
        )
        
        let configurator = PopupPresenterMenuConfigurator(items: items.jv_sort(accordingTo: location))
        configurator.configure(button: button, fallbackRecognizer: gesture)
    }
    
    func detachMenu(from button: UIButton) {
        let gesture = button.gestureRecognizers?
            .first(where: { $0 is ContextMenuGesture })
        
        let configurator = PopupPresenterMenuConfigurator(items: Array())
        configurator.reset(button: button, fallbackRecognizer: gesture)
    }
    
    func attachMenu(to barButtonItem: UIBarButtonItem, location: PopupPresenterMenuLocation, items: [PopupPresenterItem]) -> UIBarButtonItem {
        let configurator = PopupPresenterMenuConfigurator(items: items.jv_sort(accordingTo: location))
        return configurator.configure(barButtonItem: barButtonItem) { [unowned self] in
            displayMenu(
                within: .auto,
                anchor: nil,
                title: nil,
                message: nil,
                items: items + [.dismiss(.cancel)])
        }
    }
    
    func detachMenu(from barButtonItem: UIBarButtonItem) {
        let configurator = PopupPresenterMenuConfigurator(items: Array())
        configurator.reset(barButtonItem: barButtonItem)
    }
    
    func attachFlexibleMenu(to button: FlexibleMenuTriggerButton, items: [PopupPresenterFlexibleMenuItem]) {
        let gesture = FlexibleContextMenuGesture(
            target: self,
            action: #selector(handleFlexibleContextMenuGesture),
            items: items,
            button: button
        )
        
        let configurator = PopupPresenterFlexibleMenuConfigurator(items: items)
        configurator.configure(
            button: button,
            fallbackRecognizer: gesture
        )
    }
    
    func detachFlexibleMenu(from button: UIButton) {
        if let gesture = button.gestureRecognizers?
            .first(where: { $0 is FlexibleContextMenuGesture }) {
            button.removeGestureRecognizer(gesture)
        }
    }
    
    func share(within container: PopupPresenterDisplayContainer, items: [Any], performCleanup: Bool) {
        let panel = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        panel.completionWithItemsHandler = not(performCleanup) ? nil : { type, completed, objects, error in
            for item in items {
                switch item {
                case let url as URL:
                    try? FileManager.default.removeItem(at: url)
                default:
                    break
                }
            }
        }
        
        displayAsModal(within: container, viewController: panel)
    }
    
    private func constructAlert(title: String?, about: String?) -> UIAlertController {
        let alert = UIAlertController(
            title: title,
            message: about,
            preferredStyle: .alert
        )
        
        return alert
    }
    
    private func constructActionSheet(title: String?, about: String?, anchor: UIView?) -> UIAlertController {
        let alert = UIAlertController(
            title: title,
            message: about,
            preferredStyle: .actionSheet
        )
        
        if let anchor = anchor {
            alert.popoverPresentationController?.sourceView = window
            alert.popoverPresentationController?.sourceRect = anchor.convert(anchor.bounds, to: nil)
        }
        
        return alert
    }
    
    private func displayAsModal(within container: PopupPresenterDisplayContainer, viewController: UIViewController) {
        switch container {
        case .auto, .specific(nil):
            let parent = (window?.rootViewController?.presentedViewController) ?? (window?.rootViewController)
            parent?.present(viewController, animated: true)
        case .root:
            let parent = window?.rootViewController
            parent?.present(viewController, animated: true)
        case .specific(.some(let parent)):
            parent.present(viewController, animated: true)
        }
    }

    @objc private func handleContextMenuGesture(gesture: ContextMenuGesture) {
        displayMenu(
            within: .auto,
            anchor: nil,
            title: nil,
            message: nil,
            items: [.dismiss(.cancel)] + gesture.items)
    }
    
    @objc private func handleFlexibleContextMenuGesture(gesture: FlexibleContextMenuGesture) {
        displayFlexibleMenu(
            within: .auto,
            source: gesture.button as? FlexibleMenuTriggerButton,
            items: gesture.items
        )
    }
}

fileprivate final class ContextMenuGesture: UITapGestureRecognizer {
    let items: [PopupPresenterItem]
    
    init(target: Any?, action: Selector?, items: [PopupPresenterItem]) {
        self.items = items
        
        super.init(target: target, action: action)
    }
}

fileprivate final class FlexibleContextMenuGesture: UITapGestureRecognizer {
    let items: [PopupPresenterFlexibleMenuItem]
    let button: UIButton
    init(target: Any?, action: Selector?, items: [PopupPresenterFlexibleMenuItem], button: UIButton) {
        self.items = items
        self.button = button
        super.init(target: target, action: action)
    }
}

fileprivate extension Array where Element == PopupPresenterItem {
    func jv_sort(accordingTo location: PopupPresenterMenuLocation) -> Self {
        if #available(iOS 16.0, *) {
            // will be sorted by UIButton.preferredMenuElementOrder
            return self
        }
        else {
            switch location {
            case .top:
                return self
            case .bottom:
                return map { item in
                    switch item {
                    case .children(let title, let items):
                        return .children(title: title, items: items.reversed())
                    default:
                        return item
                    }
                }
                .reversed()
            }
        }
    }
}
