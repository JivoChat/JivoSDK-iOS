//
//  IncrementalStorage.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04.09.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation


protocol IIncrementalStorage: AnyObject {
    var value: Int { get set }
    func erase()
}
