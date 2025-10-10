//
//  JMTimelineRateFormCanvas.swift
//  JivoSDK
//
//  Created by Julia Popova on 26.09.2023.
//

import Foundation
import JMTimelineKit
import UIKit

final class JMTimelineRateFormCanvas: JMTimelineCanvas {
    private let control = JMTimelineRateFormControl()
    
    override init() {
        super.init()
        
        addSubview(control)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configure(item: JMTimelineItem) {
        super.configure(item: item)
        
        if let info = (item as? JMTimelineRateFormItem)?.payload {
            control.keyboardAnchorControl = info.keyboardAnchorControl
            control.adjustControl(
                config: info.rateConfig,
                accentColor: info.accentColor,
                sizing: info.sizing,
                rate: info.lastRate,
                lastComment: info.lastComment,
                rateFormPreSubmitTitle: info.rateFormPreSubmitTitle,
                rateFormPostSubmitTitle: info.rateFormPostSubmitTitle,
                rateFormCommentPlaceholder: info.rateFormCommentPlaceholder,
                rateFormSubmitCaption: info.rateFormSubmitCaption
            )
            
            control.outputHandler = { output in
                switch output {
                case .change(let choice, let comment):
                    info.interactor.toggleRateFormChange(
                        item: item,
                        choice: choice,
                        comment: comment)
                case .submit(let scale, let choice, let comment):
                    info.interactor.toggleRateFormSubmit(
                        item: item,
                        scale: scale,
                        choice: choice,
                        comment: comment)
                case .close:
                    info.interactor.toggleRateFormClose(item: item)
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
    let control: JMTimelineRateFormControl
    
    var controlFrame: CGRect {
        let size = control.jv_size(forWidth: bounds.width)
        return CGRect(x: 0, y: 0, width: size.width, height: size.height)
    }
    
    var totalSize: CGSize {
        let height = controlFrame.maxY
        return CGSize(width: bounds.width,  height: height)
    }
}
