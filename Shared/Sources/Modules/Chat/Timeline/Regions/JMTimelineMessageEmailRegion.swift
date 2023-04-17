//
//  JMTimelineMessageEmailRegion.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif
import DTModelStorage
import JMTimelineKit

final class JMTimelineMessageEmailRegion: JMTimelineMessageCanvasRegion {
    private let headersBlock = JMTimelineCompositePairsBlock()
    private let messageBlock = JMTimelineCompositePlainBlock()
    
    init() {
        super.init(renderMode: .bubble(time: .compact))
        integrateBlocks([headersBlock, messageBlock], gap: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup(uid: String, info: Any, meta: JMTimelineMessageMeta?, options: JMTimelineMessageRegionRenderOptions, provider: JVChatTimelineProvider, interactor: JVChatTimelineInteractor) {
        super.setup(uid: uid, info: info, meta: meta, options: options, provider: provider, interactor: interactor)

        if let info = info as? JMTimelineMessageEmailInfo {
            headersBlock.configure(
                headers: info.headers,
                style: JMTimelineCompositePairsStyle(
                    textColor: info.style.textColor,
                    font: JVDesign.fonts.resolve(.bold(13), scaling: .footnote)
                ))
            
            messageBlock.configure(
                content: info.message,
                style: info.style,
                provider: provider,
                interactor: interactor)
        }
    }
    
//    override func apply(style: JMTimelineStyle) {
//        super.apply(style: style)
//
//        let style = style.convert(to: JMTimelineCompositeStyle.self)
//        let contentStyle = style.contentStyle.convert(to: JMTimelineEmailStyle.self)
//
//        headersBlock.apply(
//            style: JMTimelineCompositePairsStyle(
//                textColor: contentStyle.headerColor,
//                font: contentStyle.headerFont
//            )
//        )
//
//        messageBlock.apply(
//            style: JMTimelineCompositePlainStyle(
//                textColor: contentStyle.messageColor,
//                identityColor: contentStyle.identityColor,
//                linkColor: contentStyle.linkColor,
//                font: contentStyle.messageFont,
//                boldFont: nil,
//                italicsFont: nil,
//                strikeFont: nil,
//                lineHeight: 22,
//                alignment: .natural,
//                underlineStyle: .single,
//                parseMarkdown: true)
//        )
//    }
}
