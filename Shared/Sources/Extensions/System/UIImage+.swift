//
//  UIImageExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    public static let jv_empty = UIImage()
    
    public convenience init?(jv_color color: UIColor?, size: CGSize? = nil) {
        guard let color = color else { return nil }
        let renderingSize = size ?? CGSize(width: 3, height: 3)
        
        UIGraphicsBeginImageContext(renderingSize)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(color.cgColor)
        context.fill(CGRect(origin: .zero, size: renderingSize))
        
        guard let rendered = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        if let _ = size {
            guard let image = rendered.cgImage else { return nil }
            self.init(cgImage: image)
        }
        else {
            let strethable = rendered.stretchableImage(withLeftCapWidth: 1, topCapHeight: 1)
            guard let image = strethable.cgImage else { return nil }
            self.init(cgImage: image)
        }
    }
    
    public func jv_rounded() -> UIImage? {
        let layer = CALayer()
        layer.frame = CGRect(origin: .zero, size: size)
        layer.contents = cgImage
        layer.masksToBounds = true
        layer.cornerRadius = size.width * 0.5
        
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        else {
            return nil
        }
    }
}

extension Optional where Wrapped == UIImage {
    public var jv_orEmpty: UIImage {
        return self ?? UIImage()
    }
}
