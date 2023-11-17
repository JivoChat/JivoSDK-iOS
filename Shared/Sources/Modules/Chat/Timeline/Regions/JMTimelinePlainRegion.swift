//
//  JMTimelinePlainContent.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import DTModelStorage
import JMTimelineKit


final class JMTimelineMessagePlainRegion: JMTimelineMessageCanvasRegion {
    private let quotingBlock = JMTimelineCompositeQuotingBlock(sideOffset: 0)
    private let plainBlock = JMTimelineCompositePlainBlock()
    
    init() {
        super.init(renderMode: .bubble(time: .compact))
        integrateBlocks([quotingBlock, plainBlock], gap: 5)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup(uid: String, info: Any, meta: JMTimelineMessageMeta?, options: JMTimelineMessageRegionRenderOptions, provider: JVChatTimelineProvider, interactor: JVChatTimelineInteractor) {
        super.setup(
            uid: uid,
            info: info,
            meta: meta,
            options: options,
            provider: provider,
            interactor: interactor)

        if let info = info as? JMTimelineMessagePlainInfo {
            quotingBlock.configure(
                message: info.quotedMessage,
                style: JMTimelineCompositeQuotingStyle(
                    textColor: info.style.textColor
                ),
                interactor: interactor)
            
            plainBlock.configure(
                content: info.text,
                style: info.style,
                provider: provider,
                interactor: interactor)
        }
    }
}
