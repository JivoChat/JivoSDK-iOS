//
//  JVDisplayable.swift
//  App
//
//  Created by Stan Potemkin on 16.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

protocol JVDisplayable: JVPresentable {
    var channel: ChannelEntity? { get }
    func displayName(kind: JVDisplayNameKind) -> String
    var integration: JVChannelJoint? { get }
    var hashedID: String { get }
    var isMe: Bool { get }
    var isAvailable: Bool { get }
}
