//
//  BaseProtoTypes.swift
//  App
//
//  Created by Stan Potemkin on 08.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

protocol IProto: INetworkingEventDecoder {
    func contextual(object: Any?) -> Self
}

protocol IProtoEventSubject {
}

struct ProtoEventSubjectPayload { }
protocol IProtoEventSubjectPayloadAny { }
protocol IProtoEventSubjectPayloadModel: IProtoEventSubjectPayloadAny {
    associatedtype Body
    var status: RestResponseStatus { get }
    var body: Body { get }
}

struct ProtoEventContext {
    let object: Any?
    let backsignal: JVBroadcastTool<Any>
    
    init(
        object: Any?,
        backsignal: JVBroadcastTool<Any>
    ) {
        self.object = object
        self.backsignal = backsignal
    }
}

struct ProtoEventBundle {
    let type: ProtoTransactionKind
    let id: AnyHashable?
    let subject: IProtoEventSubject
}

struct ProtoTransactionKind: Hashable {
    let identifier: String
    
    static func caseFor<T: RawRepresentable>(_ value: T) -> Self where T.RawValue == String {
        return Self(identifier: "\(String(describing: T.self)).\(value.rawValue)")
    }
    
    static func caseFor(_ value: String) -> Self {
        return Self(identifier: value)
    }
}
