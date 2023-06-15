//
//  WKWebsiteDataStoreExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 01.08.2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation
import WebKit

extension WKWebsiteDataStore {
    func discardAll() {
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        fetchDataRecords(ofTypes: types) { [weak self] records in
            self?.removeData(ofTypes: types, for: records) { }
        }
    }
}
