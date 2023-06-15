//
//  WebSocketVerbose.swift
//  App
//
//  Created by Stan Potemkin on 25.04.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import JFWebSocket

final class WebSocketVerbose: WebSocket {
    var chain: JournalChild?
}
