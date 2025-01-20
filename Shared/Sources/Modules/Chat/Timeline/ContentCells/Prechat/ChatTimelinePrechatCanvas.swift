//
//  ChatTimelinePrechatCanvas.swift
//  Pods
//
//  Created by Stan Potemkin on 07.11.2024.
//

import Foundation
import UIKit
import DTModelStorage
import JMRepicKit
import JMTimelineKit

final class ChatTimelinePrechatCanvas: JMTimelineCanvas {
    private let buttonsBlock = JMTimelineCompositeButtonsBlock(behavior: .horizontal)
    
    override init() {
        super.init()
        
        addSubview(buttonsBlock)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func link(provider: JMTimelineProvider, interactor: JMTimelineInteractor) {
    }
    
    override func configure(item: JMTimelineItem) {
        super.configure(item: item)
        
        if let info = (item as? ChatTimelinePrechatItem)?.payload {
            buttonsBlock.configure(
                captions: info.captions,
                tappable: true,
                style: .init(
                    backgroundColor: JVDesign.colors.resolve(usage: .primaryBackground),
                    borderColor: JVDesign.colors.resolve(usage: .primaryForeground),
                    captionColor: JVDesign.colors.resolve(usage: .primaryForeground),
                    captionFont: JVDesign.fonts.resolve(.regular(16), scaling: .caption1),
                    captionPadding: UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12),
                    buttonGap: 10,
                    cornerRadius: 14,
                    shadowEnabled: false
                ))
            
            buttonsBlock.tapHandler = { index in
                info.interactor.activatePrechat(caption: info.captions[index])
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
        buttonsBlock.frame = layout.buttonsBlockFrame
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            buttonsBlock: buttonsBlock
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let buttonsBlock: JMTimelineCompositeButtonsBlock
    
    var buttonsBlockFrame: CGRect {
        let size = buttonsBlock.jv_size(forWidth: bounds.width)
        let leftX = bounds.width - size.width
        return CGRect(x: leftX, y: 0, width: size.width, height: size.height)
    }
    
    var totalSize: CGSize {
        let height = buttonsBlockFrame.maxY
        return CGSize(width: bounds.width,  height: height)
    }
}
