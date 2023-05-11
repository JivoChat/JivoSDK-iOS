//
//  JVDesignEnvironment.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 11.03.2023.
//

import Foundation
import UIKit

final class JVDesignEnvironment: JVIDesignEnvironment {
    var statusBarHeight = CGFloat.zero
    var activeWindow: UIWindow?
    var previousTraits: UITraitCollection?
    
    func grabFrom(application: UIApplication, window: UIWindow) {
        if #available(iOS 13.0, *) {
            statusBarHeight = window.windowScene?.statusBarManager?.statusBarFrame.height ?? .zero
        }
        else {
            statusBarHeight = application.statusBarFrame.height
        }
        
        activeWindow = window
        previousTraits = window.traitCollection
    }
    
    func screenSize() -> JVDesignScreen {
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
    
    func effectiveHorizontalClass() -> UIUserInterfaceSizeClass {
        let sizeClass = (
            Thread.isMainThread
            ? activeWindow?.traitCollection.horizontalSizeClass
            : previousTraits?.horizontalSizeClass
        )
        
        return sizeClass ?? .compact
    }
}
