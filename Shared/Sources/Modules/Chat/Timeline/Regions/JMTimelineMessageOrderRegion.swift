//
//  JMTimelineOrderContent.swift
//  JMTimelineKit
//
//  Created by Stan Potemkin on 25.09.2020.
//

import Foundation
import JivoFoundation
import DTModelStorage
import JMTimelineKit

final class JMTimelineMessageOrderRegion: JMTimelineMessageCanvasRegion {
    private let headingBlock = JMTimelineCompositeHeadingBlock(height: 40)
    private let detailsBlock = JMTimelineCompositePlainBlock()
    private let buttonsBlock = JMTimelineCompositeButtonsBlock(behavior: .vertical)
    
    init() {
        super.init(renderMode: .bubble(time: .compact))
        integrateBlocks([headingBlock, detailsBlock, buttonsBlock], gap: 10)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup(uid: String, info: Any, meta: JMTimelineMessageMeta?, options: JMTimelineMessageRegionRenderOptions, provider: JVChatTimelineProvider, interactor: JVChatTimelineInteractor) {
        super.setup(uid: uid, info: info, meta: meta, options: options, provider: provider, interactor: interactor)

        if let info = info as? JMTimelineMessageOrderInfo {
            headingBlock.configure(
                repic: info.repic,
                repicTint: info.repicTint,
                state: info.subject,
                style: JMTimelineCompositeHeadingStyle(
                    margin: 0,
                    gap: 8,
                    iconSize: CGSize(width: 48, height: 48),
                    captionColor: JVDesign.colors.resolve(usage: .primaryForeground),
                    captionFont: obtainHeadingFont()
                ))
            
            detailsBlock.configure(
                content: info.text,
                style: JMTimelineCompositePlainStyle(
                    textColor: JVDesign.colors.resolve(usage: .secondaryForeground),
                    identityColor: JVDesign.colors.resolve(usage: .identityDetectionForeground),
                    linkColor: JVDesign.colors.resolve(usage: .identityDetectionForeground),
                    font: JVDesign.fonts.resolve(.regular(14), scaling: .body),
                    boldFont: nil,
                    italicsFont: nil,
                    strikeFont: nil,
                    lineHeight: 20,
                    alignment: .left,
                    underlineStyle: nil,
                    parseMarkdown: false
                ),
                provider: provider,
                interactor: interactor)
            
            buttonsBlock.configure(
                captions: [info.button],
                tappable: true,
                style: JMTimelineCompositeButtonsStyle(
                    backgroundColor: JVDesign.colors.resolve(usage: .secondaryButtonBackground),
                    borderColor: .clear,
                    captionColor: JVDesign.colors.resolve(usage: .secondaryButtonForeground),
                    captionFont: obtainOrderButtonFont(),
                    captionPadding: UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0),
                    buttonGap: 0,
                    cornerRadius: 10,
                    shadowEnabled: false
                ))
            
            buttonsBlock.tapHandler = { [weak self] _ in
                guard let phone = info.phone else {
                    return
                }
                
                self?.interactor?.callForOrder(phone: phone)
            }
        }
    }
    
//    override func apply(style: JMTimelineStyle) {
//        super.apply(style: style)
//
//        let style = style.convert(to: JMTimelineCompositeStyle.self)
//        let contentStyle = style.contentStyle.convert(to: JMTimelineOrderStyle.self)
//
//        headingBlock.apply(
//            style: JMTimelineCompositeHeadingStyle(
//                margin: 0,
//                gap: 8,
//                iconSize: CGSize(width: 48, height: 48),
//                captionColor: contentStyle.headingCaptionColor,
//                captionFont: contentStyle.headingCaptionFont)
//        )
//
//        detailsBlock.apply(
//            style: JMTimelineCompositePlainStyle(
//                textColor: contentStyle.detailsColor,
//                identityColor: contentStyle.contactsColor,
//                linkColor: contentStyle.contactsColor,
//                font: contentStyle.detailsFont,
//                boldFont: nil,
//                italicsFont: nil,
//                strikeFont: nil,
//                lineHeight: 20,
//                alignment: .left,
//                underlineStyle: nil,
//                parseMarkdown: false)
//        )
//
//        buttonsBlock.apply(
//            style: contentStyle.actionButton
//        )
//    }
}

fileprivate func obtainHeadingFont() -> UIFont {
    return JVDesign.fonts.resolve(.regular(16), scaling: .body)
}

private func obtainOrderButtonFont() -> UIFont {
    return JVDesign.fonts.resolve(.semibold(16), scaling: .body)
}
