//
//  JVDisplayElement.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 UI elements available for customization
 */
public enum JVDisplayElement: String, CaseIterable {
    /// Support icon in Header Bar,
    /// customizable: image
    case headerIcon
    
    /// First line in Header Bar,
    /// customizable: text, color
    case headerTitle
    
    /// Second line in Header Bar,
    /// customizable: text, color
    case headerSubtitle
    
    /// Outgoing elements from client,
    /// customizable: color
    case outgoingElements
    
    /// Textual content of Welcome Message in chat,
    /// customizable: text
    case messageWelcome
    
    /// Textual content of Offline Message in chat,
    /// customizable: text
    case messageOffline
    
    /// Placeholder for replying area,
    /// customizable: text
    case replyPlaceholder
    
    /// Text to prefill the replying area,
    /// customizable: text
    case replyPrefill
    
    /// Caption for "Take a Photo" action in Attach Menu,
    /// customizable: text
    case attachCamera
    
    /// Caption for "Choose from Library" action in Attach Menu,
    /// customizable: text
    case attachLibrary
    
    /// Caption for "Pick a Document" action in Attach Menu,
    /// customizable: text
    case attachFile
    
    /// Title for Rate Form
    /// customizable: text
    case rateFormPreSubmitTitle
    
    /// Caption for Finish Button within Rate Form
    /// customizable: text
    case rateFormPostSubmitTitle
    
    /// Placeholder for Comment Field within Rate Form
    /// customizable: text
    case rateFormCommentPlaceholder

    /// Caption for Submit Button within Rate Form
    /// customizable: text
    case rateFormSubmitCaption
}
