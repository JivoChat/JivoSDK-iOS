//
//  ContainerView.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 25.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import UIKit

final class ContainerView: UIView {
    private let contentView: UIView
    private let exactSize: CGSize?
    private let margins: UIEdgeInsets
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let found = super.hitTest(point, with: event)
        return (found == self ? contentView : found)
    }
    
    init(contentView: UIView, exactSize: CGSize? = nil, margins: UIEdgeInsets = .zero) {
        self.contentView = contentView
        self.exactSize = exactSize
        self.margins = margins
        
        super.init(frame: CGRect(origin: .zero, size: exactSize ?? .zero))
        
        preservesSuperviewLayoutMargins = false
        
        addSubview(contentView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return exactSize ?? contentView.sizeThatFits(size).jv_extendedBy(insets: margins)
    }
    
    override var intrinsicContentSize: CGSize {
        return exactSize ?? contentView.intrinsicContentSize.jv_extendedBy(insets: margins)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds.jv_reduceBy(insets: margins)
    }
}
