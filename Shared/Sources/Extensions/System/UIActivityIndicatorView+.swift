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
    func jv_started() -> UIActivityIndicatorView {
        startAnimating()
        return self
    }
    
    func jv_start() {
        startAnimating()
        isHidden = false
    }
    
    func jv_stop() {
        stopAnimating()
        isHidden = true
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
