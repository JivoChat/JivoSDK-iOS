//
//  SecureJson.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 21.12.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

struct LocalizedMeta {
    let mode: JVLocalizedMetaMode
    let args: [CVarArg]
    let suffix: String?
    let interactiveID: JMTimelineItemInteractiveID?
    
    init(
        mode: JVLocalizedMetaMode,
        args: [CVarArg],
        suffix: String?,
        interactiveID: JMTimelineItemInteractiveID?
    ) {
        self.mode = mode
        self.args = args
        self.suffix = suffix
        self.interactiveID = interactiveID
    }
    
    init(
        exact: String
    ) {
        self.mode = .exact(exact)
        self.args = Array()
        self.suffix = nil
        self.interactiveID = nil
    }
    
    func localized() -> String {
        let base: String
        switch mode {
        case .key(let key): base = loc[key]
        case .format(let format): base = String(format: loc[key: format], arguments: args)
        case .exact(let string): base = string
        @unknown default: base = String()
        }
        
        if let suffix = suffix {
            return base + suffix
        }
        else {
            return base
        }
    }
}

