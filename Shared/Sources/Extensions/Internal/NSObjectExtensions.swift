//
//  NSObjectExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04.07.2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UIAccessibilityIdentification {
    func accessible(as identifier: String) -> Self {
        accessibilityIdentifier = identifier
        return self
    }
    
    func silent() {
    }
}
