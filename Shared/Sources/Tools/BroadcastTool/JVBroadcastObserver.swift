//
//  JVBroadcastObserver.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 14/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation

public final class JVBroadcastObserver<VT> {
    public let ID: JVBroadcastObserverID
    
    private weak var broadcastTool: JVBroadcastTool<VT>?
    
    public init(ID: JVBroadcastObserverID, broadcastTool: JVBroadcastTool<VT>) {
        self.ID = ID
        self.broadcastTool = broadcastTool
    }
    
    deinit {
        broadcastTool?.removeObserver(self)
    }
}
