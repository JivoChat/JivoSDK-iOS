//
//  ChatTimelineObservableSlider.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 13/06/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit

class ChatTimelineObservableSlider: UISlider {
    var beginHandler: ((Float) -> Bool)?
    var adjustHandler: ((Float) -> Bool)?
    var endHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addTarget(self, action: #selector(handleValueChange), for: .valueChanged)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let point = touches.first?.location(in: self) {
            let progress = Float(point.x / bounds.width).jv_clamp(0, 1)
            if (beginHandler?(progress) ?? true) == true {
                value = progress
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        if let point = touches.first?.location(in: self) {
            let progress = Float(point.x / bounds.width).jv_clamp(0, 1)
            if (adjustHandler?(progress) ?? true) == true {
                value = progress
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        endHandler?()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        endHandler?()
    }
    
    @objc private func handleValueChange() {
        _ = adjustHandler?(value)
    }
}
