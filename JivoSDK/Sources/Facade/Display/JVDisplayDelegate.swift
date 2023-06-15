//
//  JVDisplayDelegate.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Acts like feedback from ``Jivo.display`` namespace
 */
@objc(JVDisplayDelegate)
public protocol JVDisplayDelegate {
    /**
     Called when the JivoSDK logic needs to display the chat UI on the screen.
     */
    @objc(jivoDisplayAsksToAppear:)
    func jivoDisplay(asksToAppear sdk: Jivo)
    
    /**
     Called before the JivoSDK opens
     */
    @objc(jivoDisplayWillAppear:)
    func jivoDisplay(willAppear sdk: Jivo)
    
    /**
     Called after the JivoSDK has closed
     */
    @objc(jivoDisplayDidDisappear:)
    func jivoDisplay(didDisappear sdk: Jivo)
    
    /**
     Here you can customize the appearance of Header Bar
     
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
     Here you can customize the captions and texts
     for some JivoSDK elements enlisted in enum
     
     - Parameter sdk:
     Reference to JivoSDK
     - Parameter forElement:
     Element for which you provide your custom setting, or nil to use the default one
     */
    @objc(jivoDisplayDefineText:forElement:)
    optional func jivoDisplay(defineText sdk: Jivo, forElement element: JVDisplayElement) -> String?
    
    /**
     Here you can customize the colors
     for some JivoSDK elements enlisted in enum
     
     - Parameter sdk:
     Reference to JivoSDK
     - Parameter forElement:
     Element for which you provide your custom setting, or nil to use the default one
     */
    @objc(jivoDisplayDefineColor:forElement:)
    optional func jivoDisplay(defineColor sdk: Jivo, forElement element: JVDisplayElement) -> UIColor?
    
    /**
     Here you can customize the icons
     for some JivoSDK elements enlisted in enum
     
     - Parameter sdk:
     Reference to JivoSDK
     - Parameter forElement:
     Element for which you provide your custom setting, or nil to use the default one
     */
    @objc(jivoDisplayDefineImage:forElement:)
    optional func jivoDisplay(defineImage sdk: Jivo, forElement element: JVDisplayElement) -> UIImage?
}
