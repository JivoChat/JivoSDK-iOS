//
//  ScheduledActionToolExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04/07/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation

extension SchedulingActionID {
    static func clientTyping(ID: Int) -> String {
        return "\(#function)::\(ID)"
    }
    
    static func meTyping(ID: Int) -> String {
        return "\(#function)::\(ID)"
    }
    
    static func sendingMessage(ID: String) -> String {
        return "\(#function)::\(ID)"
    }
    
    static func guestInviting(ID: String) -> String {
        return "\(#function)::\(ID)"
    }
}
