//
//  UIApplicationExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 27/09/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    func jv_openLocalizedURL(for key: String) {
        let link = loc[key]
        guard let url = URL(string: link) else { return }
        open(url, options: [:], completionHandler: nil)
    }
}
