//
//  UIButton+Ext.swift
//  App
//
//  Created by Yulia Popova on 24.10.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import UIKit

extension UIButton {
    var jv_image: UIImage? {
        get {
            return image(for: .normal)
        }
        set {
            setImage(newValue, for: .normal)
        }
    }
    
    func jv_setBackgroundColor(_ color: UIColor?, for state: UIControl.State) {
        guard let color = color
        else {
            setBackgroundImage(nil, for: state)
            return
        }
        
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        
        UIGraphicsBeginImageContext(rect.size)
        color.setFill()
        UIRectFill(rect)
        
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        setBackgroundImage(colorImage, for: state)
    }
}
