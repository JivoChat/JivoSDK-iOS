//
//  JVDesignEnvironment.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 11.03.2023.
//

import Foundation

public final class JVDesignEnvironment: JVIDesignEnvironment {
    public var statusBarHeight = CGFloat.zero
    public var activeWindow: UIWindow?
    public var previousTraits: UITraitCollection?
    
    public func grabFrom(application: UIApplication, window: UIWindow) {
        statusBarHeight = application.statusBarFrame.height
        activeWindow = window
        previousTraits = window.traitCollection
    }
    
    public func screenSize() -> JVDesignScreen {
        let idiom = UIDevice.current.userInterfaceIdiom
        let scale = UIScreen.main.nativeScale
        let height = UIScreen.main.nativeBounds.height / scale
        
        switch true {
        case idiom == .pad:
            return .extraLarge
        case height > 850 where scale >= 3:
            return .extraLarge
        case height > 850:
            return .large
        case height > 700 where statusBarHeight == 50:
            return .standard
        case height > 700:
            return .large
        case height > 600:
            return .standard
        default:
            return .small
        }
    }
    
    public func effectiveHorizontalClass() -> UIUserInterfaceSizeClass {
        let sizeClass = (
            Thread.isMainThread
            ? activeWindow?.traitCollection.horizontalSizeClass
            : previousTraits?.horizontalSizeClass
        )
        
        return sizeClass ?? .compact
    }
}
