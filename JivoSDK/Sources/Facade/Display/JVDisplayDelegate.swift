//
//  JVDisplayDelegate.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Interface to control displaying lifecycle,
 relates to ``Jivo.display`` namespace
 */
@objc(JVDisplayDelegate)
public protocol JVDisplayDelegate {
    /**
     Called when SDK needs to display chat UI on screen
     */
    @objc(jivoDisplayAsksToAppear:)
    func jivoDisplay(asksToAppear sdk: Jivo)
    
    /**
     Called before opening the SDK
     */
    @objc(jivoDisplayWillAppear:)
    func jivoDisplay(willAppear sdk: Jivo)
    
    /**
     Called after the SDK is closed
     */
    @objc(jivoDisplayDidDisappear:)
    func jivoDisplay(didDisappear sdk: Jivo)
    
    /**
     Called to customize Header Bar appearance
     
     - Parameter sdk:
     Reference to JivoSDK
     - Parameter navigationBar:
     Navigation Bar of Navigation Controller
     - Parameter navigationItem:
     Navigation Item of JivoSDK screen
     */
    @objc(jivoDisplayCustomizeHeader:navigationBar:navigationItem:)
    optional func jivoDisplay(customizeHeader sdk: Jivo, navigationBar: UINavigationBar, navigationItem: UINavigationItem)
    
    /**
     Called to customize captions and texts for some elements
     
     - Parameter sdk:
     Reference to JivoSDK
     - Parameter forElement:
     Element for which you provide your custom setting, or nil to use the default one
     */
    @available(*, deprecated, message: "Please use Jivo.display.define(text:forElement:) instead")
    @objc(jivoDisplayDefineText:forElement:)
    optional func jivoDisplay(defineText sdk: Jivo, forElement element: JVDisplayElement) -> String?
    
    /**
     Called to customize colors for some elements
     
     - Parameter sdk:
     Reference to JivoSDK
     - Parameter forElement:
     Element for which you provide your custom setting, or nil to use the default one
     */
    @available(*, deprecated, message: "Please use Jivo.display.define(color:forElement:) instead")
    @objc(jivoDisplayDefineColor:forElement:)
    optional func jivoDisplay(defineColor sdk: Jivo, forElement element: JVDisplayElement) -> UIColor?
    
    /**
     Called to customize icons for some elements
     
     - Parameter sdk:
     Reference to JivoSDK
     - Parameter forElement:
     Element for which you provide your custom setting, or nil to use the default one
     */
    @available(*, deprecated, message: "Please use Jivo.display.define(image:forElement:) instead")
    @objc(jivoDisplayDefineImage:forElement:)
    optional func jivoDisplay(defineImage sdk: Jivo, forElement element: JVDisplayElement) -> UIImage?
}
