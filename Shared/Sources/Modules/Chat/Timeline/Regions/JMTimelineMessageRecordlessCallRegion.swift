//
//  JMTimelineMessageRecordlessCallRegion.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation
import DTModelStorage

final class JMTimelineMessageRecordlessCallRegion: JMTimelineMessageCanvasRegion {
    private let stateBlock = JMTimelineCompositeHeadingBlock(height: 18)
    private let recordlessBlock = JMTimelineCompositeCallRecordlessBlock()
    
    init() {
        super.init(renderMode: .bubble(time: .compact))
        integrateBlocks([stateBlock, recordlessBlock], gap: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup(uid: String, info: Any, meta: JMTimelineMessageMeta?, options: JMTimelineMessageRegionRenderOptions, provider: JVChatTimelineProvider, interactor: JVChatTimelineInteractor) {
        super.setup(uid: uid, info: info, meta: meta, options: options, provider: provider, interactor: interactor)

        if let info = info as? JMTimelineMessageCallInfo {
            stateBlock.configure(
                repic: info.repic,
                repicTint: nil,
                state: info.state,
                style: JMTimelineCompositeHeadingStyle(
                    margin: 8,
                    gap: 5,
                    iconSize: CGSize(width: 18, height: 18),
                    captionColor: JVDesign.colors.resolve(usage: .primaryForeground),
                    captionFont: JVDesign.fonts.resolve(.regular(16), scaling: .caption1)
                ))
            
            recordlessBlock.configure(
                target: {
                    if let phone = info.phone {
                        return .phone(phone)
                    }
                    else {
                        return .online
                    }
                }())
        }
    }
    
//    override func apply(style: JMTimelineStyle) {
//        super.apply(style: style)
//
//        let style = style.convert(to: JMTimelineCompositeStyle.self)
//        let contentStyle = style.contentStyle.convert(to: JMTimelineCallStyle.self)
//
//        stateBlock.apply(
//            style: JMTimelineCompositeHeadingStyle(
//                margin: 8,
//                gap: 5,
//                iconSize: CGSize(width: 18, height: 18),
//                captionColor: contentStyle.stateColor,
//                captionFont: contentStyle.stateFont)
//        )
//
//        recordlessBlock.apply(
//            style: JMTimelineCompositeCallRecordlessStyle(
//                phoneTextColor: contentStyle.phoneColor,
//                phoneFont: contentStyle.phoneFont,
//                phoneLinesLimit: contentStyle.phoneLinesLimit
//            )
//        )
//    }
}
