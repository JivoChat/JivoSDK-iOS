//
//  JVDisplayCallbacks.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Interface to control displaying lifecycle,
 relates to `Jivo.display` namespace
 */
internal final class JVDisplayCallbacks {
    var asksToAppearHandler = {
    }
    
    var willAppearHandler = {
    }
    
    var didDisappearHandler = {
    }
    
    var customizeHeaderHandler = { (navigationBar: UINavigationBar, navigationItem: UINavigationItem) in
    }
}
