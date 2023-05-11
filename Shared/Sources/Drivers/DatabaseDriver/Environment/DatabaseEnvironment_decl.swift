//
//  DatabaseEnvironment.swift
//  App
//
//  Created by Stan Potemkin on 27.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

protocol JVIDatabaseEnvironment: AnyObject {
    func performMessageRecalculate(uid: String)
}
