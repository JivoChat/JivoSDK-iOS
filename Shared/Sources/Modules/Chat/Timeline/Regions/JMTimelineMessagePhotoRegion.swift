//
//  JMTimelineMessagePhotoRegion.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation
import DTModelStorage

final class JMTimelineMessagePhotoRegion: JMTimelineMessageCanvasRegion {
    private let imageBlock = JMTimelineCompositePhotoBlock(errorRendererConfiguration: .forObsoleteImageLink)
    
    init() {
        super.init(renderMode: .content(time: .over))
        integrateBlocks([imageBlock], gap: 0)
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

        if let info = info as? JMTimelineMessagePhotoInfo {
            let meta = info.scaleMeta(minimum: 120, maximum: 150)
            imageBlock.configure(
                url: info.url,
                originalSize: meta.size,
                cropped: meta.cropped,
                allowFullscreen: info.allowFullscreen,
                style: JMTimelineCompositePhotoStyle(
                    ratio: JVDesign.layout.defaultMediaRatio,
                    contentMode: info.contentMode
                ),
                provider: provider,
                interactor: interactor)
        }
    }
    
//    override func apply(style: JMTimelineStyle) {
//        super.apply(style: style)
//
//        let style = style.convert(to: JMTimelineCompositeStyle.self)
//        let contentStyle = style.contentStyle.convert(to: JMTimelinePhotoStyle.self)
//
//        imageBlock.waitingIndicatorStyle = contentStyle.waitingIndicatorStyle
//
//        imageBlock.apply(
//            style: JMTimelineCompositePhotoStyle(
//                ratio: contentStyle.ratio,
//                contentMode: contentStyle.contentMode,
//                errorStubBackgroundColor: contentStyle.errorStubStyle.backgroundColor,
//                errorStubDescriptionColor: contentStyle.errorStubStyle.errorDescriptionColor
//            )
//        )
//    }
}
