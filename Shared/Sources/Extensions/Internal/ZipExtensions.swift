//
//  ZipExtensions.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 13.01.2023.
//

import Foundation
import UIKit

extension Zip2Sequence {
    func layout() where Sequence1.Element: UIView, Sequence2.Element == CGRect {
        for (view, frame) in self {
            view.frame = frame
        }
    }
    
    func display() where Sequence1.Element: UIView, Sequence2.Element == CGFloat {
        for (view, alpha) in self {
            view.alpha = alpha
        }
    }
}
