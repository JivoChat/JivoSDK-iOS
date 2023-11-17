//
//  NetworkingHelper.swift
//  App
//
//  Created by Stan Potemkin on 08.11.2021.
//  Copyright © 2021 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

protocol INetworkingHelper: AnyObject {
    func generateRequestId() -> String
    func generateHeaders(auth: NetworkingHelperAuth, requestId: NetworkingHelperRequestId, contentType: String?) -> [String: String]
    func filter(body: JsonElement) -> JsonElement
}

enum NetworkingHelperAuth {
    case apply
    case omit
}

enum NetworkingHelperRequestId {
    case auto
    case custom(String)
}
