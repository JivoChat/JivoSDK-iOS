//
//  JWTExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 23/01/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import JWTDecode

extension JWT {
    func isExpired(since: Date?) -> Bool {
        guard let since = since else { return expired }
        guard let issuedAt = issuedAt else { return expired }
        guard let expiresAt = expiresAt else { return expired }
        
        let issuingDelta = since.timeIntervalSince(issuedAt)
        let extendedExpiration = expiresAt.addingTimeInterval(issuingDelta)
        
        return (Date() > extendedExpiration)
    }
}
