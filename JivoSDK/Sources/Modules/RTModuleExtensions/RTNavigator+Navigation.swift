//
//  RTNavigator+Navigation.swift
//  App
//
//  Created by Stan Potemkin on 13.06.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation


enum ModuleNavigationParent {
    case root(isExclusive: Bool)
    case native(_ viewController: UIViewController)
    case here(_ handler: RTEModuleJointNavigationHandler)
    case specific(_ navigator: Any)
    case responsible(_ kind: String)
}

enum ModuleNavigationEffect {
    case assign
    case embed(transition: RootTransitionMode)
    case push(animate: Bool = true)
    case present(animate: Bool = true)
}

enum ModuleNavigationFinish {
    case close(animate: Bool = true)
    case keep
}
