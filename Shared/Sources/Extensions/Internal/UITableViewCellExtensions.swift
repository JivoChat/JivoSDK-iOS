//
//  UITableViewCellExtensions.swift
//  App
//
//  Created by Stan Potemkin on 21.12.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UITableViewCell {
    static var reuseID: String {
        return String(describing: self)
    }
}
