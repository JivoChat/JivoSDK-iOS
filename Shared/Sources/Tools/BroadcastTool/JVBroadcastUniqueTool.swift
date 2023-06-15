//
//  ObservableService.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 15/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation

final class JVBroadcastUniqueTool<VT: Equatable>: JVBroadcastTool<VT> {
    private(set) var cachedValue: VT?
    
    func attachObserver(broadcastInitial: Bool, observer: @escaping JVBroadcastTool<VT>.Observer) {
        super.attachObserver(observer: observer)
        
        if let value = cachedValue {
            observer(value)
        }
    }
    
    func broadcast(_ value: VT, tag: JVBroadcastToolTag? = nil, force: Bool) {
        guard value != cachedValue || force else { return }
        cachedValue = value
        
        super.broadcast(value, tag: tag)
    }
    
    override func broadcast(_ value: VT, tag: JVBroadcastToolTag? = nil) {
        broadcast(value, tag: tag, force: false)
    }
}
