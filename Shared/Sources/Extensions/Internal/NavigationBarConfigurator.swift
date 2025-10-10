//
//  NavigationBarConfigurator.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 08.12.2020.
//

import Foundation
import UIKit

enum NavigationBarCloseButton {
    case back
    case dismiss
}

protocol NavigationBarConfigurator where Self: UIViewController {}
extension NavigationBarConfigurator {
    func configureNavigationBar(button: NavigationBarCloseButton, target: AnyObject? = nil, backButtonTapAction: Selector? = nil) {
        let cancelButton = UIBarButtonItem(image: nil, style: .plain, target: target, action: backButtonTapAction)
        cancelButton.tintColor = JVDesign.colors.resolve(usage: .primaryForeground)
        navigationItem.leftBarButtonItem = cancelButton
        
        switch button {
        case .back:
            cancelButton.image = JVDesign.icons.find(preset: .back)?.withRenderingMode(.alwaysTemplate)
        case .dismiss:
            cancelButton.image = JVDesign.icons.find(preset: .dismiss)?.withRenderingMode(.alwaysTemplate)
        }
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .medium),
            NSAttributedString.Key.foregroundColor: JVDesign.colors.resolve(usage: .primaryForeground)
        ]
    }
}
