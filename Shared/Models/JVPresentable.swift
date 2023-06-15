//
//  JVPresentable.swift
//  App
//
//  Created by Stan Potemkin on 16.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JMRepicKit

protocol JVPresentable: JVValidatable {
    var senderType: JVSenderType { get }
    func repicItem(transparent: Bool, scale: CGFloat?) -> JMRepicItem?
}
