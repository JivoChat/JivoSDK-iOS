//
//  PopupPresenterAlertConfigurator.swift
//  App
//
//  Created by Stan Potemkin on 23.02.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JivoFoundation

struct PopupPresenterAlertConfigurator: IPopupPresenterConfigurator {
    let items: [PopupPresenterItem]
    
    func configure(alert: UIAlertController) {
        for command in generateCommands(items: items) {
            command.configure(alert: alert)
        }
    }
}

fileprivate protocol PopupPresenterAlertConfiguratorCommand: PopupPresenterConfiguratorCommand {
    func configure(alert: UIAlertController)
}

fileprivate func generateCommands(items: [PopupPresenterItem]) -> [PopupPresenterAlertConfiguratorCommand] {
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

fileprivate struct ConfiguratorActionCommand: PopupPresenterAlertConfiguratorCommand {
    let title: String
    let icon: PopupPresenterItem.ActionIcon
    let state: PopupPresenterItem.ActionState
    
    func configure(alert: UIAlertController) {
        switch state {
        case .regular(let handler):
            let action = UIAlertAction(title: title, style: .default) { _ in handler?(alert.generateContext()) }
            alert.addAction(action)
        case .danger(let handler):
            let action = UIAlertAction(title: title, style: .destructive) { _ in handler?() }
            alert.addAction(action)
        case .inactive:
            let action = UIAlertAction(title: title, style: .default)
            action.isEnabled = false
            alert.addAction(action)
        }
    }
}

fileprivate struct ConfiguratorInputCommand: PopupPresenterAlertConfiguratorCommand {
    let placeholder: String?
    let value: String

    func configure(alert: UIAlertController) {
        alert.addTextField { textField in
            textField.placeholder = placeholder
            textField.text = value
        }
    }
}

fileprivate struct ConfiguratorSettingsCommand: PopupPresenterAlertConfiguratorCommand {
    func configure(alert: UIAlertController) {
        let action = UIAlertAction(title: loc["Common.Settings"], style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }
        
        alert.addAction(action)
    }
}

fileprivate struct ConfiguratorDismissCommand: PopupPresenterAlertConfiguratorCommand {
    let kind: PopupPresenterItem.DismissKind
    
    func configure(alert: UIAlertController) {
        let action = UIAlertAction(
            title: jv_convert(kind) { value in
                switch value {
                case .cancel:
                    return loc["Common.Cancel", "common_cancel"]
                case .close:
                    return loc["Common.Close", "common_close"]
                case .understand:
                    return loc["Common.Understand", "common_understand"]
                case .custom(let caption):
                    return caption
                }
            },
            style: .cancel,
            handler: { _ in
            }
        )
        
        alert.addAction(action)
    }
}

fileprivate struct ConfiguratorChildrenCommand: PopupPresenterAlertConfiguratorCommand {
    let items: [PopupPresenterItem]
    
    func configure(alert: UIAlertController) {
        for command in generateCommands(items: items) {
            command.configure(alert: alert)
        }
    }
}

fileprivate extension UIAlertController {
    func generateContext() -> PopupPresenterContext {
        let inputs = (textFields ?? Array()).map { $0.text ?? String() }
        return PopupPresenterContext(input: inputs)
    }
}
