//
//  JMTimelineMessageMediaRegion.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif
import DTModelStorage
import JMTimelineKit


struct JMTimelineMediaTriggerContactPayload: Hashable {
    let name: String
    let phone: String
}

final class JMTimelineMessageMediaRegion: JMTimelineMessageCanvasRegion {
    private let mediaBlock = JMTimelineCompositeMediaBlock()
    
    init() {
        super.init(renderMode: .bubble(time: .inline))
        integrateBlocks([mediaBlock], gap: 0)
        
        mediaBlock.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleTap))
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup(uid: String, info: Any, meta: JMTimelineMessageMeta?, options: JMTimelineMessageRegionRenderOptions, provider: JVChatTimelineProvider, interactor: JVChatTimelineInteractor) {
        super.setup(uid: uid, info: info, meta: meta, options: options, provider: provider, interactor: interactor)

        if let info = info as? JMTimelineMediaInfo {
            switch info {
            case let object as JMTimelineMediaVideoInfo:
                let formatter = DateComponentsFormatter()
                formatter.unitsStyle = .positional
                formatter.allowedUnits = [.hour, .minute, .second]
                formatter.zeroFormattingBehavior = .pad
                
                mediaBlock.configure(
                    icon: UIImage(named: "media_video", in: Bundle(for: JVDesign.self), compatibleWith: nil),
                    url: object.URL,
                    title: object.title,
                    subtitle: object.duration.flatMap(formatter.string),
                    style: object.style,
                    provider: provider,
                    interactor: interactor)
                
            case let object as JMTimelineMediaDocumentInfo:
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useGB, .useMB, .useKB, .useBytes]
                formatter.countStyle = .binary
                formatter.allowsNonnumericFormatting = false
                
                mediaBlock.configure(
                    icon: UIImage(named: "media_document", in: Bundle(for: JVDesign.self), compatibleWith: nil),
                    url: object.URL,
                    title: object.title,
                    subtitle: object.dataSize.flatMap(formatter.string),
                    style: object.style,
                    provider: provider,
                    interactor: interactor)
                
            case let object as JMTimelineMediaContactInfo:
                mediaBlock.configure(
                    icon: UIImage(named: "media_contact", in: Bundle(for: JVDesign.self), compatibleWith: nil),
                    url: nil,
                    title: object.name,
                    subtitle: object.phone,
                    style: object.style,
                    provider: provider,
                    interactor: interactor)
                
            default:
                assertionFailure()
            }
        }
    }
    
//    override func apply(style: JMTimelineStyle) {
//        super.apply(style: style)
//
//        let style = style.convert(to: JMTimelineCompositeStyle.self)
//        let contentStyle = style.contentStyle.convert(to: JMTimelineMediaStyle.self)
//
//        mediaBlock.apply(style: contentStyle)
//    }
    
    @objc private func handleTap() {
        guard let info = currentInfo else {
            return
        }
        
        switch info {
        case let object as JMTimelineMediaVideoInfo:
            interactor?.requestMedia(url: object.URL, kind: nil, mime: nil) { _ in
            }

        case let object as JMTimelineMediaDocumentInfo:
            interactor?.requestMedia(url: object.URL, kind: nil, mime: nil) { [weak self] status in
                self?.mediaBlock.configure(withMediaStatus: status)
            }

        case let object as JMTimelineMediaContactInfo:
            interactor?.addPerson(name: object.name, phone: object.phone)
            
        default:
            break
        }
    }
}
