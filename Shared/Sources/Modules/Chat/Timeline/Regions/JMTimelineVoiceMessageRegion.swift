//
//  JMTimelineVoiceMessageRegion.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import DTModelStorage
import JMTimelineKit

final class JMTimelineVoiceMessageRegion: JMTimelineMessageCanvasRegion {
    private let audioBlock = JMTimelineCompositeAudioBlock(type: .voice(.standard))
    
    init() {
        super.init(renderMode: .content(time: .over, color: .standard))
        integrateBlocks([audioBlock], gap: 0)
        
        audioBlock.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleTap))
        )
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

        
        if let info = info as? JMTimelineMessageAudioInfo {
            audioBlock.configure(
                item: info.URL,
                duration: info.duration,
                provider: provider,
                interactor: interactor,
                extendedStyle: info.style)
        }
    }
    
    @objc private func handleTap() {
        guard let info = currentInfo as? JMTimelineMessageAudioInfo else {
            return
        }
        
        interactor?.playMedia(item: info.URL)
    }
}
