//
//  ChatTimelineReferralSourceRegion.swift
//  App
//
//  Created by Stan Potemkin on 30.10.2024.
//

import Foundation
import UIKit
import DTModelStorage

final class ChatTimelineReferralSourceRegion: JMTimelineMessageCanvasRegion {
    private let imageBlock = JMTimelineCompositePhotoBlock(errorRendererConfiguration: .forObsoleteImageLink)
    private let titleBlock = JMTimelineCompositeRichBlock()
    private let textBlock = JMTimelineCompositeRichBlock()
    private let buttonsBlock = JMTimelineCompositeButtonsBlock(behavior: .vertical)
    
    init() {
        super.init(renderMode: .bubble(time: .compact))
        
        integrateBlocks([imageBlock, titleBlock, textBlock, buttonsBlock], gap: 8)
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
        
        if let info = info as? ChatTimelineReferralSourceInfo {
            let maskedCorners = CACornerMask.jv_all
//                .subtracting(info.hasAnyCaptions ? [.layerMinXMaxYCorner, .layerMaxXMaxYCorner] : .jv_empty)
            
            if let imageInfo = info.imageInfo {
                imageBlock.configure(
                    url: imageInfo.url,
                    originalSize: CGSize(width: imageInfo.width, height: imageInfo.height),
                    cropped: true,
                    allowFullscreen: true,
                    style: .init(
                        ratio: JVDesign.layout.defaultMediaRatio,
                        contentMode: .scaleAspectFill,
                        decorationColor: resolveDecorationColor(),
                        corners: maskedCorners
                    ),
                    provider: provider,
                    interactor: interactor)
            }
            else {
                imageBlock.reset()
            }
            
            if let title = info.title {
                titleBlock.configure(rich: NSAttributedString(
                    string: title,
                    attributes: [
                        .font: JVDesign.fonts.resolve(.bold(15), scaling: .body),
                        .foregroundColor: JVDesign.colors.resolve(usage: .primaryForeground).jv_withAlpha(0.78)
                    ]
                ))
            }
            else {
                titleBlock.configure(rich: NSAttributedString())
            }
            
            if let text = info.text {
                textBlock.configure(rich: NSAttributedString(
                    string: text,
                    attributes: [
                        .font: JVDesign.fonts.resolve(.regular(16), scaling: .body),
                        .foregroundColor: JVDesign.colors.resolve(usage: .primaryForeground)
                    ]
                ))
            }
            else {
                textBlock.configure(rich: NSAttributedString())
            }
            
            if let url = info.navigateUrl {
                buttonsBlock.configure(
                    captions: [loc["Message.ReferralSource.NavigateToPost"]],
                    tappable: true,
                    style: .init(
                        backgroundColor: .clear,
                        borderColor: JVDesign.colors.resolve(usage: .secondaryForeground),
                        captionColor: JVDesign.colors.resolve(usage: .primaryForeground),
                        captionFont: JVDesign.fonts.resolve(.medium(15), scaling: .body),
                        captionPadding: UIEdgeInsets(jv_by: 8),
                        buttonGap: .zero,
                        cornerRadius: 8,
                        shadowEnabled: false
                    ))
                
                buttonsBlock.tapHandler = { _ in
                    interactor.follow(url: url, interaction: .shortTap)
                }
            }
            else {
                buttonsBlock.reset()
            }
        }
    }
}
