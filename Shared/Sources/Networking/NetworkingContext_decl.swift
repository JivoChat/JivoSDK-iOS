//
//  NetworkingContextDecl.swift
//  App
//
//  Created by Stan Potemkin on 08.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

protocol INetworkingContext: AnyObject {
    var primaryDomain: String { get }
    func setPreferredDomain(_ domain: NetworkingDomain)
}
