//
//  JMTimelineMessageTaskRegion.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import DTModelStorage

final class JMTimelineMessageTaskRegion: JMTimelineMessageCanvasRegion {
    private let taskBlock = JMTimelineCompositeTaskBlock()
    
    init() {
        super.init(renderMode: .bubble(time: .standalone))
        integrateBlocks([taskBlock], gap: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup(uid: String, info: Any, meta: JMTimelineMessageMeta?, options: JMTimelineMessageRegionRenderOptions, provider: JVChatTimelineProvider, interactor: JVChatTimelineInteractor) {
        super.setup(uid: uid, info: info, meta: meta, options: options, provider: provider, interactor: interactor)

        if let info = info as? JMTimelineMessageTaskInfo {
            taskBlock.configure(
                icon: info.icon,
                brief: info.brief,
                agentRepicItem: info.agentRepic,
                agentName: info.agentName,
                date: info.date)
        }
    }
    
//    override func apply(style: JMTimelineStyle) {
//        super.apply(style: style)
//
//        let style = style.convert(to: JMTimelineCompositeStyle.self)
//        let contentStyle = style.contentStyle.convert(to: JMTimelineTaskStyle.self)
//
//        taskBlock.apply(
//            style: JMTimelineCompositeTaskStyle(
//                briefLabelColor: contentStyle.briefLabelColor,
//                briefLabelFont: contentStyle.briefLabelFont,
//                agentNameColor: contentStyle.agentNameColor,
//                agentNameFont: contentStyle.agentNameFont,
//                dateColor: contentStyle.dateColor,
//                dateFont: contentStyle.dateFont
//            )
//        )
//    }
}
