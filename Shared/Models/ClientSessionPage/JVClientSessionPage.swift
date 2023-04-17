//
//  JVPage.swift
//  App
//
//  Created by Stan Potemkin on 25.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

@objc(JVClientSessionPage)
public class JVClientSessionPage: JVPage {
    public override func apply(context: JVIDatabaseContext, change: JVDatabaseModelChange) {
        super.apply(context: context, change: change)
        performApply(context: context, environment: context.environment, change: change)
    }
}

public enum JVClientSessionPageKind: String {
    case unknown
    case start
    case history
    case current
}
