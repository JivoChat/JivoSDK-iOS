//
//  JVDisplayElement.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

@objc(JVDisplayElement)
public enum JVDisplayElement: Int {
    /// Back button in Header Bar
    case headerIcon
    
    /// First line in Header Bar
    case headerTitle
    
    /// Second line in Header Bar
    case headerSubtitle
    
    /// Outgoing elements from client
    case outgoingElements
    
    /// Textual content of Hello Message in chat
    case messageHello
    
    /// Textual content of Offline Message in chat
    case messageOffline
    
    /// Placeholder for replying area
    case replyPlaceholder
    
    /// Text to prefill the replying area
    case replyPrefill
    
    /// Caption for "Take a Photo" action in Attach Menu
    case attachCamera
    
    /// Caption for "Choose from Library" action in Attach Menu
    case attachLibrary
    
    /// Caption for "Pick a Document" action in Attach Menu
    case attachFile
}
