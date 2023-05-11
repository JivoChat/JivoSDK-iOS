//
//  JMTimelineFinishedConferenceRegion.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import DTModelStorage
import UIKit

final class JMTimelineFinishedConferenceRegion: JMTimelineMessageCanvasRegion {
    private let captionBlock = JMTimelineCompositeHeadingBlock(height: 40)
    
    init() {
        super.init(renderMode: .bubble(time: .compact))
        integrateBlocks([captionBlock], gap: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override func apply(style: JMTimelineStyle) {
//        super.apply(style: style)
//
//        let style = style.convert(to: JMTimelineCompositeStyle.self)
//        let contentStyle = style.contentStyle.convert(to: JMTimelineConferenceStyle.self)
//
//        captionBlock.apply(
//            style: JMTimelineCompositeHeadingStyle(
//                margin: 8,
//                gap: 12,
//                iconSize: CGSize(width: 40, height: 40),
//                captionColor: contentStyle.captionColor,
//                captionFont: contentStyle.captionFont)
//        )
//    }
    
    override func setup(uid: String, info: Any, meta: JMTimelineMessageMeta?, options: JMTimelineMessageRegionRenderOptions, provider: JVChatTimelineProvider, interactor: JVChatTimelineInteractor) {
        super.setup(uid: uid, info: info, meta: meta, options: options, provider: provider, interactor: interactor)

        if let info = info as? JMTimelineMessageConferenceInfo {
            captionBlock.configure(
                repic: info.repic,
                repicTint: nil,
                state: info.caption,
                style: JMTimelineCompositeHeadingStyle(
                    margin: 8,
                    gap: 12,
                    iconSize: CGSize(width: 40, height: 40),
                    captionColor: JVDesign.colors.resolve(usage: .primaryForeground),
                    captionFont: obtainCaptionFont()
                ))
        }
    }
}

fileprivate func obtainCaptionFont() -> UIFont {
    return JVDesign.fonts.resolve(.medium(16), scaling: .body)
}
