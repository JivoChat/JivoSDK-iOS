//
//  PopupPresenterTypes.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 02/06/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit

protocol IPopupPresenterBridge: AnyObject {
    var informableContainer: PopupInformingContainer { get }
    func take(window: UIWindow?)
    func displayAlert(within container: PopupPresenterDisplayContainer, title: String?, message: String?, items: [PopupPresenterItem])
    func displayMenu(within container: PopupPresenterDisplayContainer, anchor: UIView?, title: String?, message: String?, items: [PopupPresenterItem])
    func displayFlexibleMenu(within container: PopupPresenterDisplayContainer, source: FlexibleMenuTriggerButton?, items: [PopupPresenterFlexibleMenuItem])
    func informShortly(message: String)
    func informShortly(message: String?, icon: UIImage?, options: PopupPresenterShortlyOptions)
    func attachMenu(to button: UIButton, location: PopupPresenterMenuLocation, items: [PopupPresenterItem])
    func detachMenu(from button: UIButton)
    func attachMenu(to barButtonItem: UIBarButtonItem, location: PopupPresenterMenuLocation, items: [PopupPresenterItem]) -> UIBarButtonItem
    func detachMenu(from barButtonItem: UIBarButtonItem)
    func attachFlexibleMenu(to button: FlexibleMenuTriggerButton, items: [PopupPresenterFlexibleMenuItem])
    func detachFlexibleMenu(from button: UIButton)
    func share(within container: PopupPresenterDisplayContainer, items: [Any], performCleanup: Bool)
}

struct PopupPresenterContext {
    let input: [String]
}

enum PopupPresenterItem {
    case action(_ title: String, _ icon: ActionIcon, _ state: ActionState)
    case input(title: String, placeholder: String?)
    case dismiss(_ kind: DismissKind)
    case children(title: String?, items: [PopupPresenterItem])
    case settings
    case omit
}

extension PopupPresenterItem {
    struct ActionPreset {
        let title: String
        let icon: ActionIcon?
    }
    
    enum ActionIcon {
        case icon(ActionIconPreset)
        case noicon
    }
    
    struct ActionIconPreset {
        let assetName: String?
        let systemName: String?
    }
    
    enum ActionState {
        case regular(handler: ((PopupPresenterContext) -> Void)?)
        case danger(handler: (() -> Void)?)
        case inactive
    }
    
    enum DismissKind {
        case cancel
        case close
        case understand
        case custom(String)
    }
}

enum PopupPresenterFlexibleMenuItem {
    case title(_ title: String)
    case action(
        title: String,
        icon: UIImage?,
        detail: String?,
        options: PopupFlexibleMenuItemOptions,
        handler: (() -> Void)?
    )
}
