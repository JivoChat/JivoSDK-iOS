//
//  JMTimelineMessageButtonsRegion.swift
//  JMTimeline
//
//  Created by Stan Potemkin on 06.08.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif
import DTModelStorage

final class JMTimelineMessageButtonsRegion: JMTimelineMessageCanvasRegion {
    var tapHandler: ((String) -> Void)?
    
    private let buttonsBlock = JMTimelineCompositeButtonsBlock(behavior: .horizontal)

    init() {
        super.init(renderMode: .content(time: .omit), masksToBounds: false)
        integrateBlocks([buttonsBlock], gap: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup(uid: String, info: Any, meta: JMTimelineMessageMeta?, options: JMTimelineMessageRegionRenderOptions, provider: JVChatTimelineProvider, interactor: JVChatTimelineInteractor) {
        super.setup(uid: uid, info: info, meta: meta, options: options, provider: provider, interactor: interactor)

        if let info = info as? JMTimelineMessageButtonsInfo {
            buttonsBlock.configure(
                captions: info.buttons,
                tappable: info.tappable,
                style: JMTimelineCompositeButtonsStyle(
                    backgroundColor: JVDesign.colors.resolve(usage: .primaryBackground),
                    borderColor: options.outcomingPalette?.buttonsTintColor ?? JVDesign.colors.resolve(usage: .primaryForeground),
                    captionColor: options.outcomingPalette?.buttonsTintColor ?? JVDesign.colors.resolve(usage: .primaryForeground),
                    captionFont: obtainButtonFont(),
                    captionPadding: UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12),
                    buttonGap: 5,
                    cornerRadius: 14,
                    shadowEnabled: true
                ))
            
            buttonsBlock.tapHandler = { [weak self] index in
                self?.tapHandler?(info.buttons[index])
            }
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
