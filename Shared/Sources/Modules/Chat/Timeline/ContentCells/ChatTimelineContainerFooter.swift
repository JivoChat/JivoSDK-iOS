//
//  ChatTimelineContainerFooter.swift
//  JMTimeline
//
//  Created by Stan Potemkin on 07.05.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMTimelineKit

final class ChatTimelineContainerFooter: UIView {
    var captionHandler: (() -> Void)?
    var reactionHandler: ((Int) -> Void)?
    var actionHandler: ((Int) -> Void)?
    var presentReactionsHandler: (() -> Void)?

    private var allControls = [UIView]()
    private var captionLabel: UILabel?
    private var reactionControls = [JMTimelineContainerReactionControl]()
    private var actionsControls = [JMTimelineContainerReactionControl]()

    func configure(caption: String?, reactions: [ChatTimelineMessageExtrasReaction], actions: [ChatTimelineMessageExtrasAction]) {
        if let caption {
            let label = WideLabel()
            label.text = caption
            label.font = JVDesign.fonts.resolve(.regular(13), scaling: .footnote)
            label.textColor = JVDesign.colors.resolve(usage: .secondaryForeground)
            captionLabel = label
            
            label.isUserInteractionEnabled = true
            label.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(handleCaptionTap))
            )
        }
        else {
            captionLabel = nil
        }
        
        reactionControls = reactions.map(JMTimelineContainerReactionControl.init)
        for (index, control) in reactionControls.enumerated() {
            control.shortTapHandler = { [weak self] in self?.reactionHandler?(index) }
            control.longTapHandler = { [weak self] in self?.presentReactionsHandler?() }
        }
        
        actionsControls = actions.map(JMTimelineContainerReactionControl.init)
        for (index, control) in actionsControls.enumerated() {
            control.shortTapHandler = { [weak self] in self?.actionHandler?(index) }
            control.longTapHandler = { [weak self] in self?.presentReactionsHandler?() }
        }

        allControls.forEach { $0.removeFromSuperview() }
        allControls = [captionLabel].jv_flatten() + reactionControls + actionsControls
        allControls.forEach { addSubview($0) }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        zip(allControls, layout.allControlsFrames).forEach { $0.frame = $1 }
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            allControls: allControls
        )
    }
    
    @objc private func handleCaptionTap() {
        captionHandler?()
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let allControls: [UIView]
    
    private let reactionGap = CGFloat(6)
    
    var allControlsFrames: [CGRect] {
        var origin = CGPoint()
        return allControls.map { control in
            let size = control.jv_size(forWidth: bounds.width)
            defer { origin.x += size.width + reactionGap }
            
            if origin.x + size.width <= bounds.width {
                return CGRect(origin: origin, size: size)
            }
            else {
                origin.x = 0
                origin.y += size.height + reactionGap
                return CGRect(origin: origin, size: size)
            }
        }
    }
    
    var totalSize: CGSize {
        let frames = allControlsFrames
        let width = frames.map({ $0.maxX }).max() ?? 0
        let height = frames.last?.maxY ?? 0
        return CGSize(width: width, height: height)
    }
}

fileprivate final class WideLabel: UILabel {
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var result = super.sizeThatFits(size)
        result.width = size.width
        return result
    }
}
