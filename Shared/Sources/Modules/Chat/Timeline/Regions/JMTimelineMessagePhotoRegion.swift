//
//  JMTimelineMessagePhotoRegion.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import DTModelStorage

final class JMTimelineMessagePhotoRegion: JMTimelineMessageCanvasRegion {
    private let quotingBlock = JMTimelineCompositeQuotingBlock(sideOffset: 10)
    private let imageBlock = JMTimelineCompositePhotoBlock(errorRendererConfiguration: .forObsoleteImageLink)
    private let plainBlock = JMTimelineCompositePlainBlock(sideOffset: 10)
    
    init(hasCaption: Bool) {
        super.init(renderMode: .content(time: .over, color: hasCaption ? .standard : .shaded))
        
        integrateBlocks([quotingBlock, imageBlock, plainBlock], gap: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup(
        uid: String,
        info: Any,
        meta: JMTimelineMessageMeta?,
        options: JMTimelineMessageRegionRenderOptions,
        provider: JVChatTimelineProvider,
        interactor: JVChatTimelineInteractor
    ) {
        super.setup(
            uid: uid,
            info: info,
            meta: meta,
            options: options,
            provider: provider,
            interactor: interactor)
        
        if let info = info as? JMTimelineMessagePhotoInfo {
            quotingBlock.configure(
                message: info.quotedMessage,
                style: JMTimelineCompositeQuotingStyle(
                    textColor: info.contentTint
                ),
                interactor: interactor
            )
            
            let maskedCorners = CACornerMask.jv_all
                .subtracting(info.quotedMessage == nil ? .jv_empty : [.layerMinXMinYCorner, .layerMaxXMinYCorner])
                .subtracting(info.caption == nil ? .jv_empty : [.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
            
            if let textContent = info.caption, let plainStyle = info.plainStyle {
                plainBlock.configure(
                    content: textContent,
                    style: plainStyle,
                    provider: provider,
                    interactor: interactor
                )
                plainBlock.isHidden = false
            } else {
                plainBlock.isHidden = true
            }
            
            let meta = info.scaleMeta(minimum: 120, maximum: 150)
            imageBlock.configure(
                url: info.url,
                originalSize: meta.size,
                cropped: meta.cropped,
                allowFullscreen: info.allowFullscreen,
                style: JMTimelineCompositePhotoStyle(
                    ratio: JVDesign.layout.defaultMediaRatio,
                    contentMode: info.contentMode,
                    decorationColor: resolveDecorationColor(),
                    corners: maskedCorners
                ),
                provider: provider,
                interactor: interactor
            )
        }
    }
}
