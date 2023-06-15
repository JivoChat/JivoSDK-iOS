//
//  StackViewChildIcon.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 02.10.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import UIKit

final class StackViewChildIcon: UIView {
    private let underIcon = UIImageView()
    private let overIcon = UIImageView()
    
    init() {
        super.init(frame: .zero)
        
        isUserInteractionEnabled = false
        
        underIcon.contentMode = .scaleAspectFit
        addSubview(underIcon)
        
        overIcon.contentMode = .scaleAspectFit
        addSubview(overIcon)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var underImage: UIImage? {
        didSet { underIcon.image = underImage }
    }
    
    var overImage: UIImage? {
        didSet { overIcon.image = overImage }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return underIcon.sizeThatFits(size)
    }
    
    override var intrinsicContentSize: CGSize {
        return underIcon.intrinsicContentSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        underIcon.frame = bounds
        overIcon.frame = bounds
    }
}
