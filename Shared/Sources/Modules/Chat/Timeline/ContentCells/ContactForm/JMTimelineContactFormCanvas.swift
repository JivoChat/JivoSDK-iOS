//
//  JMTimelineContactFormCanvas.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import DTModelStorage
import JMRepicKit
import JMTimelineKit

final class JMTimelineContactFormCanvas: JMTimelineCanvas {
    private let control = TimelineContactFormControl()
    
    override init() {
        super.init()
        
        addSubview(control)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configure(item: JMTimelineItem) {
        super.configure(item: item)
        
        if let info = (item as? JMTimelineContactFormItem)?.payload {
            control.fields = info.fields
            control.cache = info.cache
            control.keyboardObservingBar = info.keyboardObservingBar
            control.sizing = info.sizing
            control.accentColor = info.accentColor
            
            control.outputHandler = { output in
                switch output {
                case .toggleSizing(let tag):
                    info.interactor.toggleContactForm(item: item)
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) { [weak self] in
                        self?.window?.viewWithTag(tag)?.becomeFirstResponder()
                    }
                case .submit(let values):
                    info.interactor.submitContactForm(values: values)
                }
            }
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        control.frame = layout.controlFrame
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            control: control
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let control: TimelineContactFormControl
    
    var controlFrame: CGRect {
        let size = control.jv_size(forWidth: bounds.width)
        return CGRect(x: 0, y: 0, width: size.width, height: size.height)
    }
    
    var totalSize: CGSize {
        let height = controlFrame.maxY
        return CGSize(width: bounds.width,  height: height)
    }
}
