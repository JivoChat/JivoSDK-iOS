//
//  ReachabilityDriver.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04/06/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import Reachability

final class ReachabilityDriver: IReachabilityDriver {
    typealias ReachabilityBlock = (ReachabilityMode) -> Void
    
    private let reachability: Reachability?
    private var listeningBlocks = [ReachabilityBlock]()
    
    init() {
        reachability = try? Reachability()
        
        reachability?.whenReachable = { [unowned self] _ in
            self.informListeners()
        }
        
        reachability?.whenUnreachable = { [unowned self] _ in
            self.informListeners()
        }
    }
    
    var isReachable: Bool {
        return !(reachability?.connection == .unavailable)
    }
    
    var currentMode: ReachabilityMode {
        switch reachability?.connection ?? .unavailable {
        case .none: return .none
        case .unavailable: return .none
        case .wifi: return .wifi
        case .cellular: return .cell
        }
    }
    
    func start() {
        try? reachability?.startNotifier()
    }
    
    func addListener(block: @escaping ReachabilityBlock) {
        listeningBlocks.append(block)
    }
    
    func stop() {
        reachability?.stopNotifier()
    }
    
    private func informListeners() {
        let blocks = listeningBlocks
        let mode = currentMode
        
        DispatchQueue.main.async {
            blocks.forEach { $0(mode) }
        }
    }
}
