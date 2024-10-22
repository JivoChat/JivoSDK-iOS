//
//  JMTimelineMessageLocationRegion.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import DTModelStorage
import JMTimelineKit

final class JMTimelineMessageLocationRegion: JMTimelineMessageCanvasRegion {
    private let locationBlock = JMTimelineCompositeLocationBlock()
    
    init() {
        super.init(renderMode: .content(time: .over))
        integrateBlocks([locationBlock], gap: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup(uid: String, info: Any, meta: JMTimelineMessageMeta?, options: JMTimelineMessageRegionRenderOptions, provider: JVChatTimelineProvider, interactor: JVChatTimelineInteractor) {
        super.setup(uid: uid, info: info, meta: meta, options: options, provider: provider, interactor: interactor)

        if let info = info as? JMTimelineMessageLocationInfo {
            locationBlock.configure(
                coordinate: info.coordinate,
                style: JMTimelineCompositeLocationBlockStyle(
                    ratio: JVDesign.layout.defaultMediaRatio
                ),
                provider: provider,
                interactor: interactor)
        }
    }
    
//    override func apply(style: JMTimelineStyle) {
//        super.apply(style: style)
//
//        let style = style.convert(to: JMTimelineCompositeStyle.self)
//        let contentStyle = style.contentStyle.convert(to: JMTimelineLocationStyle.self)
//        locationBlock.apply(style: contentStyle)
//    }
}
