//
//  PopupPresenterMenuConfigurator.swift
//  App
//
//  Created by Stan Potemkin on 23.02.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import UIKit

struct PopupPresenterMenuConfigurator: IPopupPresenterConfigurator {
    let items: [PopupPresenterItem]
    
    func configure(button: UIButton, fallbackRecognizer: UIGestureRecognizer) {
        if #available(iOS 14.0, *) {
            button.menu = generateMenu()
            button.showsMenuAsPrimaryAction = true
            
            if #available(iOS 16.0, *) {
                button.preferredMenuElementOrder = .fixed
            }
        }
        else {
            button.addGestureRecognizer(fallbackRecognizer)
        }
    }
    
    func reset(button: UIButton, fallbackRecognizer: UIGestureRecognizer?) {
        if #available(iOS 14.0, *) {
            button.menu = nil
            button.showsMenuAsPrimaryAction = false
        }
        else if let gesture = fallbackRecognizer {
            button.removeGestureRecognizer(gesture)
        }
    }
    
    func configure(barButtonItem: UIBarButtonItem, fallbackHandler: @escaping () -> Void) -> UIBarButtonItem {
        if #available(iOS 14.0, *) {
            barButtonItem.menu = generateMenu()
            
            if #available(iOS 16.0, *) {
                barButtonItem.preferredMenuElementOrder = .fixed
            }
            
            return barButtonItem
        }
        else {
            let item = WrapperBarItem(customIcon: barButtonItem.image)
            item.tapHandler = fallbackHandler
            return item
        }
    }
    
    func reset(barButtonItem: UIBarButtonItem) {
        if #available(iOS 14.0, *) {
            barButtonItem.menu = nil
        }
        else if let item = barButtonItem as? WrapperBarItem {
            item.tapHandler = nil
        }
    }
    
    @available(iOS 13.0, *)
    private func generateMenu() -> UIMenu {
        let commands = generateCommands(items: [.children(items: items)])
        let actions = commands.compactMap { $0.generateAction() }
        return UIMenu(options: .displayInline, children: actions)
    }
}

@available(iOS 13.0, *)
fileprivate protocol ConfiguratorCommand: PopupPresenterConfiguratorCommand {
    func generateAction() -> UIMenuElement?
}

@available(iOS 13.0, *)
fileprivate func generateCommands(items: [PopupPresenterItem]) -> [ConfiguratorCommand] {
    return items.compactMap { item in
        switch item {
        case .action(let title, let icon, let state):
            return ConfiguratorActionCommand(title: title, icon: icon, state: state)
        case .input(let title, let placeholder):
            return ConfiguratorInputCommand(placeholder: placeholder, value: title)
        case .settings:
            return ConfiguratorSettingsCommand()
        case .dismiss(let kind):
            return ConfiguratorDismissCommand(kind: kind)
        case .children(let children):
            return ConfiguratorChildrenCommand(items: children)
        case .omit:
            return nil
        }
    }
}

@available(iOS 13.0, *)
fileprivate struct ConfiguratorActionCommand: ConfiguratorCommand {
    let title: String
    let icon: PopupPresenterItem.ActionIcon
    let state: PopupPresenterItem.ActionState
    
    func generateAction() -> UIMenuElement? {
        let image: UIImage? = jv_convert(icon) { value in
            switch value {
            case .icon(let preset):
                return (
                    UIImage?.none
                    ?? preset.assetName.flatMap(UIImage.init(named:))?.withRenderingMode(.alwaysTemplate)
                    ?? preset.systemName.flatMap(UIImage.init(systemName:))
                )
            case .noicon:
                return nil
            }
        }
        
        switch state {
        case .regular(let handler):
            return UIAction(title: title, image: image) { _ in
                let context = PopupPresenterContext(input: Array())
                handler?(context)
            }
        case .danger(let handler):
            return UIAction(title: title, image: image, attributes: .destructive) { _ in
                handler?()
            }
        case .inactive:
            return UIAction(title: title, image: image, attributes: .disabled) { _ in
            }
        }
    }
}

@available(iOS 13.0, *)
fileprivate struct ConfiguratorInputCommand: ConfiguratorCommand {
    let placeholder: String?
    let value: String
    
    func generateAction() -> UIMenuElement? {
        return nil
    }
}

@available(iOS 13.0, *)
fileprivate struct ConfiguratorSettingsCommand: ConfiguratorCommand {
    func generateAction() -> UIMenuElement? {
        return UIAction(title: loc["Common.Settings"]) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }
    }
}

@available(iOS 13.0, *)
fileprivate struct ConfiguratorDismissCommand: ConfiguratorCommand {
    let kind: PopupPresenterItem.DismissKind
    
    func generateAction() -> UIMenuElement? {
        return nil
    }
}

@available(iOS 13.0, *)
fileprivate struct ConfiguratorChildrenCommand: ConfiguratorCommand {
    let items: [PopupPresenterItem]
    
    func generateAction() -> UIMenuElement? {
        return generateMenu()
    }
    
    private func generateMenu() -> UIMenuElement? {
        let commands = generateCommands(items: items)
        let actions = commands.compactMap { $0.generateAction() }
        return UIMenu(options: .displayInline, children: actions)
    }
}
