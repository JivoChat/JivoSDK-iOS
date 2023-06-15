//
//  IncrementalPreferencesStorage.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04.09.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation


final class IncrementalPreferencesStorage: IIncrementalStorage {
    private let accessor: PreferencesAccessor
    
    init(accessor: PreferencesAccessor) {
        self.accessor = accessor
    }
    
    var value: Int {
        get { accessor.number }
        set { accessor.number = newValue }
    }
    
    func erase() {
        accessor.erase()
    }
}
