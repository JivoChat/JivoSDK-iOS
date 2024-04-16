//
//  BaseProto.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 31.07.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

class BaseProto: IProto {
    let userContextAny: AnyObject?
    let socketUUID: UUID
    let networking: INetworking
    let networkingHelper: INetworkingHelper
    let uuidProvider: IUUIDProvider

    init(userContext: AnyObject?,
         socketUUID: UUID,
         networking: INetworking,
         networkingHelper: INetworkingHelper,
         uuidProvider: IUUIDProvider) {
        self.userContextAny = userContext
        self.socketUUID = socketUUID
        self.networking = networking
        self.networkingHelper = networkingHelper
        self.uuidProvider = uuidProvider
    }
    
    func contextual(object: Any?) -> Self {
        _ = networking.contextual(object: object)
        return self
    }
    
    func decodeToSubject(event: NetworkingSubject) -> IProtoEventSubject? {
        return nil
    }
    
    func decodeToBundle(event: NetworkingSubject) -> ProtoEventBundle? {
        return nil
    }
}
