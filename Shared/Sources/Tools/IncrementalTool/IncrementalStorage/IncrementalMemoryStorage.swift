//
//  IncrementalMemoryStorage.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04.09.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation


final class IncrementalMemoryStorage: IIncrementalStorage {
    var value = Int(0)
    
    func erase() {
        value = 0
    }
}
