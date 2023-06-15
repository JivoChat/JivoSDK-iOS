//
//  JMTimelineMessageRichRegion.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import TypedTextAttributes
import DTModelStorage
import JMTimelineKit

final class JMTimelineMessageRichRegion: JMTimelineMessageCanvasRegion {
    private let richBlock = JMTimelineCompositeRichBlock()
    
    init() {
        super.init(renderMode: .bubble(time: .compact))
        integrateBlocks([richBlock], gap: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup(uid: String, info: Any, meta: JMTimelineMessageMeta?, options: JMTimelineMessageRegionRenderOptions, provider: JVChatTimelineProvider, interactor: JVChatTimelineInteractor) {
        super.setup(uid: uid, info: info, meta: meta, options: options, provider: provider, interactor: interactor)
        
        if let info = info as? JMTimelineMessageRichInfo {
            richBlock.configure(rich: info.content)
        }
    }
    
//    override func apply(style: JMTimelineStyle) {
//        super.apply(style: style)
//
//        let style = style.convert(to: JMTimelineCompositeStyle.self)
//        let contentStyle = style.contentStyle.convert(to: JMTimelineRichStyle.self)
//
//        richBlock.apply(style: contentStyle)
//    }
}
