//
//  UIActivityIndicatorViewExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04.10.2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UIActivityIndicatorView {
    public func jv_started() -> UIActivityIndicatorView {
        startAnimating()
        return self
    }
}

extension UIActivityIndicatorView.Style {
    public static var jv_auto: UIActivityIndicatorView.Style {
        if #available(iOS 13.0, *) {
            return .medium
        }
        else {
            return .gray
        }
    }
}
