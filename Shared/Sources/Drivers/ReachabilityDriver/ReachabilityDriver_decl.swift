//
//  ReachabilityTypes.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04/06/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation

protocol IReachabilityDriver: AnyObject {
    var isReachable: Bool { get }
    var currentMode: ReachabilityMode { get }
    func start()
    func addListener(block: @escaping (ReachabilityMode) -> Void)
    func stop()
}

enum ReachabilityMode: String {
    case none
    case cell
    case wifi
}

extension ReachabilityMode {
    var hasNetwork: Bool {
        switch self {
        case .none: return false
        case .cell: return true
        case .wifi: return true
        }
    }
}
