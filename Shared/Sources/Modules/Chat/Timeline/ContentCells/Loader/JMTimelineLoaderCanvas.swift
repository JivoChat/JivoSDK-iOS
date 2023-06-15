//
//  JMTimelineLoaderCanvas.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import DTModelStorage
import JMTimelineKit

final class JMTimelineLoaderCanvas: JMTimelineCanvas {
    private let waitingIndicator = UIActivityIndicatorView()
    
    override init() {
        super.init()
        
        waitingIndicator.startAnimating()
        addSubview(waitingIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override func apply(style: JMTimelineStyle) {
//        super.apply(style: style)
//
//        let style = style.convert(to: JMTimelineLoaderStyle.self)
//
//        waitingIndicator.style = style.waitingIndicatorStyle
//    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: 50)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        waitingIndicator.frame = bounds
    }
}

