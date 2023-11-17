//
//  NetworkingHelper.swift
//  App
//
//  Created by Stan Potemkin on 08.11.2021.
//  Copyright © 2021 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit
@testable import App

final class NetworkingHelperMock: INetworkingHelper {
    init() {
    }
    
    func generateRequestId() -> String {
        fatalError()
    }
    
    func generateHeaders(auth: NetworkingHelperAuth, requestId: NetworkingHelperRequestId, contentType: String?) -> [String: String] {
        fatalError()
    }
    
    func filter(body: JsonElement) -> JsonElement {
        fatalError()
    }
}
