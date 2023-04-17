//
//  NetworkingHelper.swift
//  App
//
//  Created by Stan Potemkin on 08.11.2021.
//  Copyright © 2021 JivoSite. All rights reserved.
//

import Foundation


protocol INetworkingHelper: AnyObject {
    func generateRequestId() -> String
    func generateHeaders(auth: NetworkingHelperAuth, requestId: NetworkingHelperRequestId, contentType: String?) -> [String: String]
}

enum NetworkingHelperAuth {
    case apply
    case omit
}

enum NetworkingHelperRequestId {
    case auto
    case custom(String)
}

final class NetworkingHelper: INetworkingHelper {
    private let uuidProvider: IUUIDProvider
    private let keychainTokenAccessor: IKeychainAccessor
    
    init(uuidProvider: IUUIDProvider, keychainTokenAccessor: IKeychainAccessor) {
        self.uuidProvider = uuidProvider
        self.keychainTokenAccessor = keychainTokenAccessor
    }
    
    func generateRequestId() -> String {
        return UUID().uuidString
            .jv_stringByRemovingSymbols(of: .alphanumerics.inverted)
            .prefix(13)
            .lowercased()
    }
    
    func generateHeaders(auth: NetworkingHelperAuth, requestId: NetworkingHelperRequestId, contentType: String?) -> [String: String] {
        var ret = [
            "User-Agent": uuidProvider.userAgentBrief,
            "x-app-instance-id": uuidProvider.currentInstallationID
        ]
        
        if let token = keychainTokenAccessor.string, auth == .apply {
            ret["Authorization"] = token
        }
        
        switch requestId {
        case .auto:
            ret["x-request-id"] = generateRequestId()
        case .custom(let value):
            ret["x-request-id"] = value
        }
        
        if let contentType = contentType {
            ret["Content-Type"] = contentType
        }
        
        return ret
    }
}
