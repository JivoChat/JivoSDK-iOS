//
//  JVDesignEnvironment.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 11.03.2023.
//

import Foundation

public protocol JVIDesignEnvironment {
    var statusBarHeight: CGFloat { get }
    var activeWindow: UIWindow? { get }
    var previousTraits: UITraitCollection? { get }
    func grabFrom(application: UIApplication, window: UIWindow)
    func screenSize() -> JVDesignScreen
    func effectiveHorizontalClass() -> UIUserInterfaceSizeClass
}

public enum JVDesignScreen: Int, Comparable {
    case small
    case standard
    case large
    case extraLarge
    
    public static func < (lhs: JVDesignScreen, rhs: JVDesignScreen) -> Bool {
        guard lhs.rawValue < rhs.rawValue else { return false }
        return true
    }
}
