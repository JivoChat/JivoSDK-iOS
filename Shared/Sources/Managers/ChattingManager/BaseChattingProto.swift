//
//  BaseChattingProto.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 02.09.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit


protocol IBaseChattingProtoConverter {
    init()
    func convertToSubject(meta: IProtoEventSubjectPayloadAny) -> IProtoEventSubject?
}

struct ChattingSubMedia {
    let type: String
    let mime: String
    let name: String
    let link: String
    let dataSize: Int
    let width: Int
    let height: Int
}

protocol IBaseChattingProto: IProto {
}

class BaseChattingProto<Converter: IBaseChattingProtoConverter>: BaseProto, IBaseChattingProto {
    private let converter = Converter.init()
    
}

extension ProtoEventSubjectPayload {
}
