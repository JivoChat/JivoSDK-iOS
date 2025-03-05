//
//  JMTimelineMessageBotRegion.swift
//  JMTimeline
//
//  Created by Stan Potemkin on 06.08.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import DTModelStorage

final class JMTimelineMessageBotRegion: JMTimelineMessageCanvasRegion {
    private let plainBlock = JMTimelineCompositePlainBlock()
    private let buttonsBlock = JMTimelineCompositeButtonsBlock(behavior: .horizontal)

    init() {
        super.init(renderMode: .bubble(time: .compact))
        integrateBlocks([plainBlock, buttonsBlock], gap: 20)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup(uid: String, info: Any, meta: JMTimelineMessageMeta?, options: JMTimelineMessageRegionRenderOptions, provider: JVChatTimelineProvider, interactor: JVChatTimelineInteractor) {
        super.setup(uid: uid, info: info, meta: meta, options: options, provider: provider, interactor: interactor)

        if let info = info as? JMTimelineMessageBotInfo {
            plainBlock.configure(
                content: info.text,
                style: info.style,
                provider: provider,
                interactor: interactor)
            
            buttonsBlock.configure(
                captions: info.buttons,
                tappable: info.tappable,
                style: JMTimelineCompositeButtonsStyle(
                    backgroundColor: JVDesign.colors.resolve(usage: .primaryBackground),
                    borderColor: .clear,
                    captionColor: JVDesign.colors.resolve(usage: .primaryForeground),
                    captionFont: obtainButtonFont(),
                    captionPadding: UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8),
                    buttonGap: 5,
                    cornerRadius: 8,
                    shadowEnabled: false
                ))
        }
    }
    
//    override func apply(style: JMTimelineStyle) {
//        super.apply(style: style)
//
//        let style = style.convert(to: JMTimelineCompositeStyle.self)
//        let contentStyle = style.contentStyle.convert(to: JMTimelineBotStyle.self)
//
//        plainBlock.apply(style: contentStyle.plainStyle)
//        buttonsBlock.apply(style: contentStyle.buttonsStyle)
//    }
}

private func obtainButtonFont() -> UIFont {
    return JVDesign.fonts.resolve(.regular(16), scaling: .caption1)
}
