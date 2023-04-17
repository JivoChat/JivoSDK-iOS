//
//  NavigationBarConfigurator.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 08.12.2020.
//

import UIKit
#if canImport(JivoFoundation)
import JivoFoundation
#endif

enum NavigationBarCloseButton {
    case back
    case dismiss
}

protocol NavigationBarConfigurator where Self: UIViewController {}
extension NavigationBarConfigurator {
    func configureNavigationBar(button: NavigationBarCloseButton, target: AnyObject? = nil, backButtonTapAction: Selector? = nil) {
        let cancelButton = UIBarButtonItem(image: nil, style: .plain, target: target, action: backButtonTapAction)
        navigationItem.leftBarButtonItem = cancelButton
        
        switch button {
        case .back:
            cancelButton.image = JVDesign.icons.find(preset: .back)
        case .dismiss:
            cancelButton.image = JVDesign.icons.find(preset: .dismiss)
        }
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .medium),
            NSAttributedString.Key.foregroundColor: JVDesign.colors.resolve(usage: .primaryForeground)
        ]
    }
}
