//
//  ToggleButton.swift
//  App
//
//  Created by Yulia Popova on 16.06.2023.
//

import UIKit

class ToggleButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        setImage(nil, for: .normal)
        setBackgroundImage(nil, for: .normal)
        
        setImage(UIImage.jv_named("check-plain"), for: .highlighted)
        setBackgroundImage(UIImage(jv_color: JVDesign.colors.resolve(usage: .checkmarkOnBackground)), for: .highlighted)
        
        setImage(UIImage.jv_named("check-plain"), for: .selected)
        setBackgroundImage(UIImage(jv_color: JVDesign.colors.resolve(usage: .checkmarkOnBackground)), for: .selected)
        
        layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
