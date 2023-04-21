//
//  ChatTimelineFactory.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 17/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

import UIKit
import DTCollectionViewManager
import JMTimelineKit
import TypedTextAttributes
import JMRepicKit
import BABFrameObservingInputAccessoryView
import JMCodingKit

#if ENV_APP
import Lottie
#endif

fileprivate let ChatTimelineFiredReminderUUID = UUID().uuidString

enum ChatTimelineActionID: String {
    case reminderComplete
}

enum ChatTimelineSenderType {
    case client
    case agent
    case comment
    case info
    case call
    case bot
    case story
    case neutral
}

enum JMTimelineResource {
    case image(UIImage)
    case video(URL)
    case raw(Data)
    case failure(errorDescription: String? = nil)
    
//#if ENV_APP
//    case lottie(LottieAnimation)
//#endif
}

fileprivate enum ChatTimelineBackgroundType {
    case regular
    case comment
    case specialDark
    case specialLight
    case failed
}

struct ChatTimelinePalette {
    let backgroundColor: UIColor
    let foregroundColor: UIColor
    let buttonsTintColor: UIColor
    let inputTintColor: UIColor
}

struct ChatTimelineDisablingOptions: OptionSet {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }
    static let delivery = ChatTimelineDisablingOptions(rawValue: 1 << 0)
    static let clientUserpic = ChatTimelineDisablingOptions(rawValue: 1 << 1)
}

enum ChatTimelineBotStyle {
    case inner
    case outer
}

enum ChatTimelineMessagePosition {
    case recent
    case history
}

final class ChatTimelineContactFormCache {
    var values = [String: String]()
    
    func save(id: String, value: String?) {
        values[id] = value
    }
    
    func read(id: String) -> String? {
        return values[id]
    }
    
    func reset() {
        values.removeAll()
    }
}

final class ChatTimelineFactory: JMTimelineFactory {
    fileprivate struct SystemButtonStyle {
        let backgroundColor: UIColor
        let textColor: UIColor
        let font: UIFont
        let margins: UIEdgeInsets
        let underlineStyle: NSUnderlineStyle
        let cornerRadius: CGFloat
    }
    
    private let userContext: IBaseUserContext
    private let databaseDriver: JVIDatabaseDriver
    private let systemMessagingService: ISystemMessagingService
    private let provider: JVChatTimelineProvider
    private let interactor: JVChatTimelineInteractor
    private let isGroup: Bool
    private let disablingOptions: ChatTimelineDisablingOptions
    private let botStyle: ChatTimelineBotStyle
    private let displayNameKind: JVDisplayNameKind
    private let outcomingPalette: ChatTimelinePalette?
    private let keyboardObservingBar: BABFrameObservingInputAccessoryView
    private let contactFormCache: ChatTimelineContactFormCache

    private let botSenderUUID = UUID().uuidString
    private let noneSenderUUID = UUID().uuidString
    
    init(userContext: IBaseUserContext,
         databaseDriver: JVIDatabaseDriver,
         systemMessagingService: ISystemMessagingService,
         provider: JVChatTimelineProvider,
         interactor: JVChatTimelineInteractor,
         isGroup: Bool,
         disablingOptions: ChatTimelineDisablingOptions,
         botStyle: ChatTimelineBotStyle,
         displayNameKind: JVDisplayNameKind,
         outcomingPalette: ChatTimelinePalette?,
         keyboardObservingBar: BABFrameObservingInputAccessoryView,
         contactFormCache: ChatTimelineContactFormCache
    ) {
        self.userContext = userContext
        self.databaseDriver = databaseDriver
        self.systemMessagingService = systemMessagingService
        self.provider = provider
        self.interactor = interactor
        self.isGroup = isGroup
        self.disablingOptions = disablingOptions
        self.botStyle = botStyle
        self.displayNameKind = displayNameKind
        self.outcomingPalette = outcomingPalette
        self.keyboardObservingBar = keyboardObservingBar
        self.contactFormCache = contactFormCache
        
        super.init()
    }
    
    override func register(manager: DTCollectionViewManager, providers: JMTimelineDataSourceProviders) {
        manager.registerFooter(JMTimelineDateHeaderView.self)
        manager.register(JMTimelineLoaderCell.self)
        manager.register(JMTimelineMessageCell.self)
        manager.register(JMTimelineSystemCell.self)
        manager.register(JMTimelineTimepointCell.self)
        manager.register(JMTimelineContactFormCell.self)
        
        manager.referenceSizeForFooterView(withItem: JMTimelineDateItem.self, providers.headerSizeProvider)
        manager.sizeForCell(withItem: JMTimelineLoaderItem.self, providers.cellSizeProvider)
        manager.sizeForCell(withItem: JMTimelineMessageItem.self, providers.cellSizeProvider)
        manager.sizeForCell(withItem: JMTimelineSystemItem.self, providers.cellSizeProvider)
        manager.sizeForCell(withItem: JMTimelineTimepointItem.self, providers.cellSizeProvider)
        manager.sizeForCell(withItem: JMTimelineContactFormItem.self, providers.cellSizeProvider)

        manager.willDisplay(JMTimelineLoaderCell.self, providers.willDisplayHandler)
        manager.willDisplay(JMTimelineMessageCell.self, providers.willDisplayHandler)
        manager.willDisplay(JMTimelineSystemCell.self, providers.willDisplayHandler)
        manager.willDisplay(JMTimelineTimepointCell.self, providers.willDisplayHandler)
        manager.willDisplay(JMTimelineContactFormCell.self, providers.willDisplayHandler)

        manager.didSelect(JMTimelineSystemCell.self, providers.didSelectHandler)
    }
    
    override func generateItem(for date: Date) -> JMTimelineItem {
        return JMTimelineDateItem(
            uid: UUID().uuidString,
            date: date,
            layoutValues: JMTimelineItemLayoutValues(
                margins: UIEdgeInsets(top: 9, left: 0, bottom: 4, right: 0),
                groupingCoef: 0
            ),
            logicOptions: [.enableSizeCaching, .isVirtual],
            extraActions: JMTimelineExtraActions(),
            payload: JMTimelineDateInfo(
                caption: provider.formattedDateForGroupHeader(date)
            )
        )
    }
    
    func generateLoaderItem() -> JMTimelineItem {
        return JMTimelineLoaderItem(
            uid: UUID().uuidString,
            date: Date.distantPast,
            layoutValues: JMTimelineItemLayoutValues(
                margins: UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0),
                groupingCoef: 0
            ),
            logicOptions: [.enableSizeCaching, .isVirtual],
            extraActions: JMTimelineExtraActions(),
            payload: JMTimelineLoaderInfo()
        )
    }
    
    func generateItem(for message: JVMessage, position: ChatTimelineMessagePosition) -> JMTimelineItem {
        guard !(message.isDeleted) else {
            return generatePlainItem(for: message)
        }
        
        switch message.content {
        case .left: return generateSystemItem(for: message)
        case .join: return generateSystemItem(for: message)
        case .transfer: return generateSystemItem(for: message)
        case .task: return generateReminderItem(for: message)
        case .comment: return generateCommentItem(for: message)
        case .bot: return generateBotItem(for: message, position: position)
        case .order: return generateOrderItem(for: message)
        case .contactForm(let status): return generateContactFormItem(for: message, status: status)
        default: break
        }
        
        if let media = message.media, media.jv_isValid {
            switch media.type {
            case .photo: return generatePhotoItem(for: message, contentMode: .scaleAspectFill)
            case .video: return generateVideoItem(for: message)
            case .audio: return generateAudioItem(for: message)
            case .voice: return generateVoiceMessageItem(for: message)
            case .sticker: return generateStickerItem(for: message)
            case .document: return generateDocumentItem(for: message)
            case .comment: return generatePlainItem(for: message)
            case .location: return generateLocationItem(for: message)
            case .contact: return generateContactItem(for: message)
            case .conference: return generateConferenceItem(for: message)
            case .story: return generateStoryItem(for: message)
            case .unknown: return generatePlainItem(for: message)
            }
        }
        else if let _ = message.call {
            return generateCallItem(for: message)
        }
        else if case .email = message.content {
            return generateEmailItem(for: message)
        }
        else if let agent = message.senderAgent, agent.ID < 0 {
            return generateBotItem(for: message, position: position)
        }
        else if let _ = message.text.jv_oneEmojiString() {
            return generateStickerItem(for: message)
        }
        else if message.direction == .system {
            return generateSystemItem(for: message)
        }
        else {
            return generatePlainItem(for: message)
        }
    }
    
    func generateSystemItem(icon: JMRepicItem?,
                            meta: LocalizedMeta,
                            buttons: [JMTimelineSystemButtonMeta],
                            countable: Bool) -> JMTimelineItem {
        return JMTimelineSystemItem(
            uid: UUID().uuidString,
            date: Date(),
            layoutValues: JMTimelineItemLayoutValues(
                margins: UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0),
                groupingCoef: 0
            ),
            logicOptions: (
                countable
                ? [.enableSizeCaching]
                : [.enableSizeCaching, .isVirtual]
            ),
            extraActions: JMTimelineExtraActions(),
            payload: JMTimelineSystemInfo(
                icon: icon,
                text: meta.localized(),
                style: _generateSystemItem_style(
                    font: obtainSmallSystemFont(),
                    textColor: .secondaryForeground,
                    alignment: .center
                ),
                interactiveID: nil,
                provider: provider,
                interactor: interactor,
                buttons: buttons
            )
        )
    }
    
    func generateSystemItem(uid: String?, date: Date, text: String, countable: Bool) -> JMTimelineItem {
        return JMTimelineSystemItem(
            uid: uid ?? UUID().uuidString,
            date: date,
            layoutValues: generateSystemLayoutValues(),
            logicOptions: (
                countable
                ? [.enableSizeCaching]
                : [.enableSizeCaching, .isVirtual]
            ),
            extraActions: JMTimelineExtraActions(),
            payload: JMTimelineSystemInfo(
                icon: nil,
                text: text,
                style: _generateSystemItem_style(
                    font: obtainMediumSystemFont(),
                    textColor: .primaryForeground,
                    alignment: .natural
                ),
                interactiveID: nil,
                provider: provider,
                interactor: interactor,
                buttons: []
            )
        )
    }
    
    private func generateSystemItem(for message: JVMessage) -> JMTimelineItem {
        return JMTimelineSystemItem(
            uid: message.UUID,
            date: message.date,
            layoutValues: generateSystemLayoutValues(),
            logicOptions: (
                message.hasIdentity
                ? [.enableSizeCaching]
                : [.enableSizeCaching, .isVirtual]
            ),
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineSystemInfo(
                icon: message.contextImageURL(transparent: false),
                text: systemMessagingService.generatePreviewPlain(
                    isGroup: isGroup,
                    message: message),
                style: _generateSystemItem_style(
                    font: obtainSystemSmallFont(),
                    textColor: .secondaryForeground,
                    alignment: .center
                ),
                interactiveID: message.interactiveID,
                provider: provider,
                interactor: interactor,
                buttons: []
            )
        )
    }
    
    private func _generateSystemItem_style(
        font: UIFont,
        textColor: JVDesignColorUsage,
        alignment: NSTextAlignment
    ) -> JMTimelineCompositePlainStyle {
        return JMTimelineCompositePlainStyle(
            textColor: JVDesign.colors.resolve(usage: textColor),
            identityColor: JVDesign.colors.resolve(usage: .identityDetectionForeground),
            linkColor: JVDesign.colors.resolve(usage: .linkDetectionForeground),
            font: font,
            boldFont: nil,
            italicsFont: nil,
            strikeFont: nil,
            lineHeight: 17,
            alignment: alignment,
            underlineStyle: nil,
            parseMarkdown: false
        )
    }
    
    func generateTypingItem(sender: JVDisplayable?, text: String) -> JMTimelineItem {
        let basicColor: UIColor
        switch sender?.senderType ?? .client {
        case .client:
            basicColor = JVDesign.colors.resolve(usage: .clientForeground)
        case .agent:
            basicColor = JVDesign.colors.resolve(usage: .agentForeground)
        default:
            basicColor = JVDesign.colors.resolve(usage: .agentForeground)
            assertionFailure()
        }
        
        let font = JVDesign.fonts.resolve(.regular(16), scaling: .callout)
        
        let text = NSAttributedString(
            string: text,
            attributes: TextAttributes()
                .foregroundColor(basicColor)
                .font(font)
        )
        
        let separator = NSAttributedString(
            string: " …\u{200a}",
            attributes: TextAttributes()
                .foregroundColor(basicColor)
                .font(font)
                .baselineOffset(-1)
        )
        
        let symbol = NSAttributedString(
            string: "\u{e836}",
            attributes: TextAttributes()
                .foregroundColor(basicColor)
                .font(JVDesign.fonts.entypo(ofSize: 13.0))
                .baselineOffset(0)
        )
        
        let content = NSMutableAttributedString()
        content.append(text)
        content.append(separator)
        content.append(symbol)
        
        let uid = UUID().uuidString
        
        return JMTimelineMessageItem(
            uid: uid,
            date: Date(),
            layoutValues: generateMessageLayoutValues(),
            logicOptions: [.enableSizeCaching, .isVirtual],
            extraActions: JMTimelineExtraActions(),
            payload: JMTimelineMessagePayload(
                kindID: #function,
                sender: JMTimelineItemSender(
                    ID: sender?.hashedID ?? String(),
                    icon: sender?.repicItem(transparent: false, scale: nil),
                    name: nil,
                    mark: nil,
                    style: _obtainItemSender_style(contentKind: .neutral)
                ),
                renderOptions: JMTimelineMessageRenderOptions(
                    position: .left
                ),
                provider: provider,
                interactor: interactor,
                regionsGenerator: {
                    let richRegion = JMTimelineMessageRichRegion()
                    return [richRegion]
                },
                regionsPopulator: { [provider, interactor] regions in
                    if let richRegion = regions.first as? JMTimelineMessageRichRegion {
                        richRegion.setup(
                            uid: uid,
                            info: JMTimelineMessageRichInfo(
                                content: content
                            ),
                            meta: nil,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: .left,
                                contentKind: .client,
                                outcomingPalette: nil,
                                isQuote: false,
                                entireCanvas: false,
                                isFailure: false
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                }
            )
        )
    }
    
    func generateReminderItem(for reminder: JVTask) -> JMTimelineItem {
        let payload = reminder.convertToMessageBody()
        return JMTimelineSystemItem(
            uid: ChatTimelineFiredReminderUUID,
            date: Date(),
            layoutValues: JMTimelineItemLayoutValues(
                margins: UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0),
                groupingCoef: 0
            ),
            logicOptions: [.isVirtual],
            extraActions: JMTimelineExtraActions(),
            payload: JMTimelineSystemInfo(
                icon: nil,
                text: systemMessagingService.generateTaskPreview(
                    task: payload,
                    by: reminder.agent!,
                    status: payload.status
                ),
                style: _generateReminderItem_style(
                    font: obtainSystemSmallFont(),
                    textColor: .secondaryForeground,
                    alignment: .center
                ),
                interactiveID: nil,
                provider: provider,
                interactor: interactor,
                buttons: [
                    JMTimelineSystemButtonMeta(
                        ID: ChatTimelineActionID.reminderComplete.rawValue,
                        title: loc["Reminder.CompleteAction"]
                    )
                ]
            )
        )
    }
    
    private func _generateReminderItem_style(
        font: UIFont,
        textColor: JVDesignColorUsage,
        alignment: NSTextAlignment
    ) -> JMTimelineCompositePlainStyle {
        return JMTimelineCompositePlainStyle(
            textColor: JVDesign.colors.resolve(usage: textColor),
            identityColor: JVDesign.colors.resolve(usage: .identityDetectionForeground),
            linkColor: JVDesign.colors.resolve(usage: .linkDetectionForeground),
            font: font,
            boldFont: nil,
            italicsFont: nil,
            strikeFont: nil,
            lineHeight: 17,
            alignment: alignment,
            underlineStyle: nil,
            parseMarkdown: false
        )
    }
    
    func generateTimepointItem(date: Date, caption: String) -> JMTimelineItem {
        return JMTimelineTimepointItem(
            uid: UUID().uuidString,
            date: date,
            layoutValues: JMTimelineItemLayoutValues(
                margins: UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0),
                groupingCoef: 0
            ),
            logicOptions: [.enableSizeCaching],
            extraActions: JMTimelineExtraActions(),
            payload: JMTimelineTimepointInfo(
                caption: caption
            )
        )
    }
    
    override func generateCanvas(for item: JMTimelineItem) -> JMTimelineCanvas {
        switch item {
        case _ as JMTimelineDateItem:
            return JMTimelineDateHeaderCanvas()
        case _ as JMTimelineLoaderItem:
            return JMTimelineLoaderCanvas()
        case _ as JMTimelineMessageItem:
            return JMTimelineMessageCanvas()
        case _ as JMTimelineSystemItem:
            return JMTimelineSystemCanvas()
        case _ as JMTimelineContactFormItem:
            return JMTimelineContactFormCanvas()
        case _ as JMTimelineTimepointItem:
            return JMTimelineTimepointCanvas()
        default:
            assertionFailure()
            return JMTimelineMessageCanvas()
        }
    }
    
    //    private func obtainDateStyle() -> JMTimelineStyle {
    //        return JMTimelineItemLayoutValues(
    //            margins: UIEdgeInsets(top: 9, left: 0, bottom: 4, right: 0),
    //            groupingCoef: 0,
    //            contentStyle: JMTimelineDateHeaderStyle(
    //                backgroundColor: JVDesign.colors.resolve(usage: .primaryBackground),
    //                shadowColor: JVDesign.colors.resolve(usage: .focusingShadow),
    //                foregroundColor: JVDesign.colors.resolve(usage: .secondaryForeground),
    //                foregroundFont: JVDesign.fonts.resolve(
    //                    weight: .light,
    //                    category: .caption1,
    //                    defaultSizes: DesignFontSizeLegacy(compact: 12, regular: 12),
    //                    maximumSizes: nil
    //                )
    //            )
    //        )
    //    }
    
    //    private func obtainSystemStyle(margins: UIEdgeInsets?, font: UIFont, color: DesignColorUsage, alignment: NSTextAlignment) -> JMTimelineStyle {
    //        return JMTimelineItemLayoutValues(
    //            margins: margins ?? UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0),
    //            groupingCoef: 0,
    //            contentStyle: JMTimelineSystemStyle(
    //                messageTextColor: JVDesign.colors.resolve(usage: color),
    //                messageFont: font,
    //                messageAlignment: alignment,
    //                identityColor: JVDesign.colors.resolve(usage: .identityDetectionForeground),
    //                linkColor: JVDesign.colors.resolve(usage: .linkDetectionForeground),
    //                buttonBackgroundColor: UIColor.clear,
    //                buttonTextColor: JVDesign.colors.resolve(usage: .actionActiveButtonForeground),
    //                buttonFont: JVDesign.fonts.resolve(
    //                    weight: .regular,
    //                    category: .subheadline,
    //                    defaultSizes: DesignFontSizeLegacy(compact: 14, regular: 14),
    //                    maximumSizes: nil
    //                ),
    //                buttonMargins: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
    //                buttonUnderlineStyle: [],
    //                buttonCornerRadius: 0
    //            )
    //        )
    //    }
    
    //    private func obtainTimepointStyle() -> JMTimelineStyle {
    //        return JMTimelineItemLayoutValues(
    //            margins: UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0),
    //            groupingCoef: 0,
    //            contentStyle: JMTimelineTimepointStyle(
    //                margins: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15),
    //                alignment: .center,
    //                font: obtainTimepointFont(),
    //                textColor: JVDesign.colors.resolve(usage: .attentiveTint),
    //                padding: UIEdgeInsets(top: 7, left: 16, bottom: 7, right: 16),
    //                borderWidth: 1,
    //                borderColor: JVDesign.colors.resolve(usage: .attentiveTint),
    //                borderRadius: nil)
    //        )
    //    }
    
    private func generatePlainItem(for message: JVMessage) -> JMTimelineItem {
        let uid = message.UUID
        let position = obtainItemPosition(for: message)
        let sender = detectSenderType(for: message)
        let palette = obtainItemPalette(for: message)
        let isFailure = message.delivery.isFailure
        
        let messageInfo = JMTimelineMessagePlainInfo(
            text: message.text,
            style: JMTimelineCompositePlainStyle(
                textColor: _generatePlainItem_textColor(sender: sender, isDeleted: message.isDeleted),
                identityColor: _generatePlainItem_identityColor(sender: sender),
                linkColor: _generatePlainItem_linkColor(sender: sender),
                font: _generatePlainItem_regularFont(isDeleted: message.isDeleted),
                boldFont: _generatePlainItem_boldFont(),
                italicsFont: _generatePlainItem_italicsFont(),
                strikeFont: _generatePlainItem_regularFont(isDeleted: message.isDeleted),
                lineHeight: 22,
                alignment: .natural,
                underlineStyle: .single,
                parseMarkdown: message.isMarkdown
            )
        )
        
        let messageMeta = generateMessageMeta(
            message: message
        )
        
        return JMTimelineMessageItem(
            uid: uid,
            date: message.date,
            layoutValues: generateMessageLayoutValues(),
            logicOptions: [.enableSizeCaching],
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineMessagePayload(
                kindID: #function,
                sender: obtainItemSender(for: message),
                renderOptions: JMTimelineMessageRenderOptions(
                    position: position
                ),
                provider: provider,
                interactor: interactor,
                regionsGenerator: {
                    let plainRegion = JMTimelineMessagePlainRegion()
                    return [plainRegion]
                },
                regionsPopulator: { [provider, interactor] regions in
                    if let plainRegion = regions.first as? JMTimelineMessagePlainRegion {
                        plainRegion.setup(
                            uid: uid,
                            info: messageInfo,
                            meta: messageMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: position,
                                contentKind: sender,
                                outcomingPalette: palette,
                                isQuote: false,
                                entireCanvas: false,
                                isFailure: isFailure
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                }
            )
        )
    }
    
    private func _generatePlainItem_textColor(sender: ChatTimelineSenderType, isDeleted: Bool) -> UIColor {
        guard !(isDeleted) else {
            return JVDesign.colors.resolve(usage: .agentForeground).jv_withAlpha(0.5)
        }
        
        switch sender {
        case .client: return JVDesign.colors.resolve(usage: .clientForeground)
        case .agent: return JVDesign.colors.resolve(usage: .agentForeground)
        case .comment: return JVDesign.colors.resolve(usage: .agentForeground)
        case .call: return JVDesign.colors.resolve(usage: .secondaryForeground)
        case .info: return JVDesign.colors.resolve(usage: .agentForeground)
        case .bot: return JVDesign.colors.resolve(usage: .agentForeground)
        case .story: return JVDesign.colors.resolve(usage: .clientForeground)
        case .neutral: return JVDesign.colors.resolve(usage: .clientForeground)
        }
    }
    
    private func _generatePlainItem_identityColor(sender: ChatTimelineSenderType) -> UIColor {
        switch sender {
        case .client: return JVDesign.colors.resolve(usage: .clientLinkForeground)
        case .agent: return JVDesign.colors.resolve(usage: .agentLinkForeground)
        case .comment: return JVDesign.colors.resolve(usage: .agentLinkForeground)
        case .call: return JVDesign.colors.resolve(usage: .identityDetectionForeground)
        case .info: return JVDesign.colors.resolve(usage: .agentLinkForeground)
        case .bot: return JVDesign.colors.resolve(usage: .agentLinkForeground)
        case .story: return JVDesign.colors.resolve(usage: .clientLinkForeground)
        case .neutral: return JVDesign.colors.resolve(usage: .clientLinkForeground)
        }
    }
    
    private func _generatePlainItem_linkColor(sender: ChatTimelineSenderType) -> UIColor {
        switch sender {
        case .client: return JVDesign.colors.resolve(usage: .clientLinkForeground)
        case .agent: return JVDesign.colors.resolve(usage: .agentLinkForeground)
        case .comment: return JVDesign.colors.resolve(usage: .agentLinkForeground)
        case .call: return JVDesign.colors.resolve(usage: .linkDetectionForeground)
        case .info: return JVDesign.colors.resolve(usage: .agentLinkForeground)
        case .bot: return JVDesign.colors.resolve(usage: .agentLinkForeground)
        case .story: return JVDesign.colors.resolve(usage: .clientLinkForeground)
        case .neutral: return JVDesign.colors.resolve(usage: .clientLinkForeground)
        }
    }
    
    private func _generatePlainItem_regularFont(isDeleted: Bool) -> UIFont {
        let weight: JVDesignFontWeight = isDeleted ? .italics : .regular
        let meta = JVDesignFontMeta(weight: weight, sizing: 16)
        return JVDesign.fonts.resolve(meta, scaling: .callout)
    }
    
    private func _generatePlainItem_boldFont() -> UIFont {
        return JVDesign.fonts.resolve(.bold(16), scaling: .callout)
    }
    
    private func _generatePlainItem_italicsFont() -> UIFont {
        return JVDesign.fonts.resolve(.italics(16), scaling: .callout)
    }
    
    private func generateOrderItem(for message: JVMessage) -> JMTimelineItem {
        guard case let .order(email, phone, _, details, button) = message.content else {
            return generatePlainItem(for: message)
        }
        
        let messageInfo = JMTimelineMessageOrderInfo(
            repic: JMRepicItem(
                backgroundColor: JVDesign.colors.resolve(usage: .orderTint),
                source: .named(asset: "timeline.order", template: true),
                scale: 0.5,
                clipping: .external),
            repicTint: JVDesign.colors.resolve(usage: .oppositeForeground),
            subject: loc["Chat.Order.Placeholder.Title"],
            email: email,
            phone: phone,
            text: details,
            button: button
        )
        
        let messageMeta = generateMessageMeta(
            message: message
        )
        
        let uid = message.UUID
        let position = obtainItemPosition(for: message)
        let sender = detectSenderType(for: message)
        let palette = obtainItemPalette(for: message)
        let isFailure = message.delivery.isFailure
        
        return JMTimelineMessageItem(
            uid: uid,
            date: message.date,
            layoutValues: generateMessageLayoutValues(),
            logicOptions: [.enableSizeCaching],
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineMessagePayload(
                kindID: #function,
                sender: obtainItemSender(for: message),
                renderOptions: JMTimelineMessageRenderOptions(
                    position: position
                ),
                provider: provider,
                interactor: interactor,
                regionsGenerator: {
                    let orderRegion = JMTimelineMessageOrderRegion()
                    return [orderRegion]
                },
                regionsPopulator: { [provider, interactor] regions in
                    if let orderRegion = regions.first as? JMTimelineMessageOrderRegion {
                        orderRegion.setup(
                            uid: uid,
                            info: messageInfo,
                            meta: messageMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: position,
                                contentKind: sender,
                                outcomingPalette: palette,
                                isQuote: false,
                                entireCanvas: false,
                                isFailure: isFailure
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                }
            )
        )
    }
    
    private func generateBotItem(for message: JVMessage, position: ChatTimelineMessagePosition) -> JMTimelineItem {
        switch botStyle {
        case .inner:
            return generateBotInnerItem(for: message)
        case .outer:
            return generateBotOuterItem(for: message, position: position)
        }
    }
    
    private func generateBotInnerItem(for message: JVMessage) -> JMTimelineItem {
        let uid = message.UUID
        let contentKind = detectSenderType(for: message)
        let palette = obtainItemPalette(for: message)
        let isFailure = message.delivery.isFailure
        
        let messageInfo = JMTimelineMessageBotInfo(
            text: message.text,
            style: JMTimelineCompositePlainStyle(
                textColor: JVDesign.colors.resolve(usage: .agentForeground),
                identityColor: JVDesign.colors.resolve(usage: .identityDetectionForeground),
                linkColor: JVDesign.colors.resolve(usage: .linkDetectionForeground),
                font: _generateBotItem_regularFont(isDeleted: message.isDeleted),
                boldFont: _generateBotItem_boldFont(isDeleted: message.isDeleted),
                italicsFont: _generateBotItem_italicsFont(isDeleted: message.isDeleted),
                strikeFont: nil,
                lineHeight: 20,
                alignment: .natural,
                underlineStyle: .single,
                parseMarkdown: true
            ),
            buttons: message.buttons,
            tappable: false
        )
        
        let messageMeta = generateMessageMeta(
            message: message
        )
        
        return JMTimelineMessageItem(
            uid: uid,
            date: message.date,
            layoutValues: generateMessageLayoutValues(),
            logicOptions: (
                message.hasIdentity
                ? [.enableSizeCaching]
                : [.enableSizeCaching, .isVirtual]
            ),
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineMessagePayload(
                kindID: #function,
                sender: obtainItemSender(for: message),
                renderOptions: JMTimelineMessageRenderOptions(
                    position: .left
                ),
                provider: provider,
                interactor: interactor,
                regionsGenerator: {
                    let botRegion = JMTimelineMessageBotRegion()
                    return [botRegion]
                },
                regionsPopulator: { [provider, interactor] regions in
                    if let botRegion = regions.first as? JMTimelineMessageBotRegion {
                        botRegion.setup(
                            uid: uid,
                            info: messageInfo,
                            meta: messageMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: .left,
                                contentKind: contentKind,
                                outcomingPalette: palette,
                                isQuote: false,
                                entireCanvas: false,
                                isFailure: isFailure
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                }
            )
        )
    }
    
    private func generateBotOuterItem(for message: JVMessage, position: ChatTimelineMessagePosition) -> JMTimelineItem {
        let uid = message.UUID
        let contentKind = detectSenderType(for: message)
        let palette = obtainItemPalette(for: message)
        let isFailure = message.delivery.isFailure
        
        let messageInfo = JMTimelineMessageBotInfo(
            text: message.text,
            style: JMTimelineCompositePlainStyle(
                textColor: JVDesign.colors.resolve(usage: .agentForeground),
                identityColor: JVDesign.colors.resolve(usage: .identityDetectionForeground),
                linkColor: JVDesign.colors.resolve(usage: .linkDetectionForeground),
                font: _generateBotItem_regularFont(isDeleted: message.isDeleted),
                boldFont: _generateBotItem_boldFont(isDeleted: message.isDeleted),
                italicsFont: _generateBotItem_italicsFont(isDeleted: message.isDeleted),
                strikeFont: nil,
                lineHeight: 20,
                alignment: .natural,
                underlineStyle: .single,
                parseMarkdown: true
            ),
            buttons: Array(),
            tappable: false
        )
        
        let buttonsInfo = JMTimelineMessageButtonsInfo(
            buttons: message.buttons,
            tappable: true
        )
        
        let messageMeta = generateMessageMeta(
            message: message
        )
        
        struct Controls: OptionSet {
            let rawValue: Int
            static let empty = Self(rawValue: 0 << 0)
            static let message = Self(rawValue: 1 << 0)
            static let buttons = Self(rawValue: 1 << 1)
        }
        
        let controls = Controls.empty
            .union(message.text.isEmpty ? .empty : .message)
            .union((position == .recent && !(message.buttons.isEmpty)) ? .buttons : .empty)
        
        return JMTimelineMessageItem(
            uid: uid,
            date: message.date,
            layoutValues: generateMessageLayoutValues(),
            logicOptions: (
                message.hasIdentity
                ? []
                : [.isVirtual]
            ),
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineMessagePayload(
                kindID: #function + (
                    String()
                    + (controls.contains(.message) ? ":message" : String())
                    + (controls.contains(.buttons) ? ":buttons" : String())
                ),
                sender: {
                    switch controls {
                    case .empty, .buttons:
                        return JMTimelineItemSender(
                            ID: UUID().uuidString,
                            icon: nil,
                            name: nil,
                            mark: nil,
                            style: JMTimelineMessageSenderStyle(
                                backgroundColor: .clear,
                                foregroundColor: .clear,
                                font: .systemFont(ofSize: 10),
                                padding: .zero,
                                corner: .zero
                            )
                        )
                    default:
                        return obtainItemSender(for: message)
                    }
                }(),
                renderOptions: JMTimelineMessageRenderOptions(
                    position: .left,
                    senderIconOffset: 1
                ),
                provider: provider,
                interactor: interactor,
                regionsGenerator: {
                    let botRegion = JMTimelineMessageBotRegion()
                    let buttonsRegion = JMTimelineMessageButtonsRegion()
                    
                    switch controls {
                    case .empty:
                        return Array()
                    case .message:
                        return [botRegion]
                    case .buttons:
                        return [buttonsRegion]
                    default:
                        return [botRegion, buttonsRegion]
                    }
                },
                regionsPopulator: { [provider, interactor] regions in
                    for region in regions {
                        if let botRegion = region as? JMTimelineMessageBotRegion {
                            botRegion.setup(
                                uid: uid,
                                info: messageInfo,
                                meta: messageMeta,
                                options: JMTimelineMessageRegionRenderOptions(
                                    position: .left,
                                    contentKind: contentKind,
                                    outcomingPalette: palette,
                                    isQuote: false,
                                    entireCanvas: false,
                                    isFailure: isFailure
                                ),
                                provider: provider,
                                interactor: interactor)
                        }
                        else if let buttonsRegion = region as? JMTimelineMessageButtonsRegion {
                            buttonsRegion.setup(
                                uid: uid,
                                info: buttonsInfo,
                                meta: messageMeta,
                                options: JMTimelineMessageRegionRenderOptions(
                                    position: .left,
                                    contentKind: .neutral,
                                    outcomingPalette: palette,
                                    isQuote: false,
                                    entireCanvas: false,
                                    isFailure: isFailure
                                ),
                                provider: provider,
                                interactor: interactor)
                            
                            buttonsRegion.tapHandler = { [weak self] text in
                                self?.interactor.sendMessage(text: text)
                            }
                        }
                    }
                }
            )
        )
    }
    
    private func _generateBotItem_regularFont(isDeleted: Bool) -> UIFont {
        let weight: JVDesignFontWeight = isDeleted ? .italics : .regular
        let meta = JVDesignFontMeta(weight: weight, sizing: 16)
        return JVDesign.fonts.resolve(meta, scaling: .callout)
    }
    
    private func _generateBotItem_boldFont(isDeleted: Bool) -> UIFont {
        let weight: JVDesignFontWeight = isDeleted ? .italics : .bold
        let meta = JVDesignFontMeta(weight: weight, sizing: 16)
        return JVDesign.fonts.resolve(meta, scaling: .callout)
    }
    
    private func _generateBotItem_italicsFont(isDeleted: Bool) -> UIFont {
        return JVDesign.fonts.resolve(.italics(16), scaling: .callout)
    }
    
    private func generateContactFormItem(for message: JVMessage, status: JVMessageBodyContactFormStatus) -> JMTimelineItem {
        let details = JsonCoder().decode(raw: message.rawDetails) ?? .null
        return JMTimelineContactFormItem(
            uid: message.UUID,
            date: message.date,
            layoutValues: generateSystemLayoutValues(),
            logicOptions: (
                message.hasIdentity
                ? []
                : [.isVirtual]
            ),
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineContactFormInfo(
                fields: [
                    TimelineContactFormField(
                        id: "name",
                        placeholder: loc["contact_form.name.placeholder"],
                        value: details["name"].string?.jv_valuable,
                        keyboardType: .default,
                        interactivity: .enabled
                    ),
                    TimelineContactFormField(
                        id: "phone",
                        placeholder: loc["contact_form.phone.placeholder"],
                        value: details["phone"].string?.jv_valuable,
                        keyboardType: .phonePad,
                        interactivity: .enabled
                    ),
                    TimelineContactFormField(
                        id: "email",
                        placeholder: loc["contact_form.email.placeholder"],
                        value: details["email"].string?.jv_valuable,
                        keyboardType: .emailAddress,
                        interactivity: .enabled
                    )
                ],
                cache: contactFormCache,
                sizing: status,
                accentColor: outcomingPalette?.backgroundColor,
                interactiveID: message.interactiveID,
                keyboardObservingBar: keyboardObservingBar,
                provider: provider,
                interactor: interactor
            )
        )
    }

    private func generatePhotoItem(for message: JVMessage, contentMode: UIView.ContentMode) -> JMTimelineItem {
//        return generateContactFormItem(for: message)
        
        guard let media = message.media, let url = media.fullURL ?? media.thumbURL else {
            return generatePlainItem(for: message)
        }
        
        let messageInfo = JMTimelineMessagePhotoInfo(
            url: url,
            width: Int(media.originalSize.width),
            height: Int(media.originalSize.height),
            contentMode: contentMode,
            allowFullscreen: true
        )
        
        let messageMeta = generateMessageMeta(
            message: message
        )
        
        let uid = message.UUID
        let position = obtainItemPosition(for: message)
        let contentKind = detectSenderType(for: message)
        let palette = obtainItemPalette(for: message)
        let isFailure = message.delivery.isFailure
        
        return JMTimelineMessageItem(
            uid: uid,
            date: message.date,
            layoutValues: generateMessageLayoutValues(),
            logicOptions: (
                message.hasIdentity
                ? [.enableSizeCaching]
                : [.enableSizeCaching, .isVirtual]
            ),
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineMessagePayload(
                kindID: #function,
                sender: obtainItemSender(for: message),
                renderOptions: JMTimelineMessageRenderOptions(
                    position: position
                ),
                provider: provider,
                interactor: interactor,
                regionsGenerator: {
                    let photoRegion = JMTimelineMessagePhotoRegion()
                    return [photoRegion]
                },
                regionsPopulator: { [provider, interactor] regions in
                    if let photoRegion = regions.first as? JMTimelineMessagePhotoRegion {
                        photoRegion.setup(
                            uid: uid,
                            info: messageInfo,
                            meta: messageMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: position,
                                contentKind: contentKind,
                                outcomingPalette: palette,
                                isQuote: false,
                                entireCanvas: true,
                                isFailure: isFailure
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                }
            )
        )
    }
    
    private func generateVideoItem(for message: JVMessage) -> JMTimelineItem {
        guard let media = message.media, let url = media.fullURL ?? media.thumbURL else {
            return generatePlainItem(for: message)
        }
        
        let uid = message.UUID
        let position = obtainItemPosition(for: message)
        let contentKind = detectSenderType(for: message)
        let palette = obtainItemPalette(for: message)
        let isFailure = message.delivery.isFailure
        
        let messageInfo = JMTimelineMediaVideoInfo(
            URL: url,
            title: media.name,
            duration: media.duration.ifPositive(),
            style: JMTimelineMediaStyle(
                iconTintColor: _generateVideoItem_iconColor(sender: contentKind),
                titleColor: _generateVideoItem_textColor(sender: contentKind, isDeleted: message.isDeleted),
                subtitleColor: _generateVideoItem_textColor(sender: contentKind, isDeleted: message.isDeleted).jv_withAlpha(0.6)
            )
        )
        
        let messageMeta = generateMessageMeta(
            message: message
        )
        
        return JMTimelineMessageItem(
            uid: uid,
            date: message.date,
            layoutValues: generateMessageLayoutValues(),
            logicOptions: (
                message.hasIdentity
                ? [.enableSizeCaching]
                : [.enableSizeCaching, .isVirtual]
            ),
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineMessagePayload(
                kindID: #function,
                sender: obtainItemSender(for: message),
                renderOptions: JMTimelineMessageRenderOptions(
                    position: position
                ),
                provider: provider,
                interactor: interactor,
                regionsGenerator: {
                    let mediaRegion = JMTimelineMessageMediaRegion()
                    return [mediaRegion]
                },
                regionsPopulator: { [provider, interactor] regions in
                    if let mediaRegion = regions.first as? JMTimelineMessageMediaRegion {
                        mediaRegion.setup(
                            uid: uid,
                            info: messageInfo,
                            meta: messageMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: position,
                                contentKind: contentKind,
                                outcomingPalette: palette,
                                isQuote: false,
                                entireCanvas: false,
                                isFailure: isFailure
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                }
            )
        )
    }
    
    private func _generateVideoItem_iconColor(sender: ChatTimelineSenderType) -> UIColor {
        switch sender {
        case .client: return JVDesign.colors.resolve(usage: .clientBackground)
        case .agent: return JVDesign.colors.resolve(usage: .agentBackground)
        case .comment: return JVDesign.colors.resolve(usage: .agentBackground)
        case .call: return JVDesign.colors.resolve(usage: .agentBackground)
        case .info: return JVDesign.colors.resolve(usage: .agentBackground)
        case .bot: return JVDesign.colors.resolve(usage: .agentBackground)
        case .story: return JVDesign.colors.resolve(usage: .clientBackground)
        case .neutral: return JVDesign.colors.resolve(usage: .agentBackground)
        }
    }
    
    private func _generateVideoItem_textColor(sender: ChatTimelineSenderType, isDeleted: Bool) -> UIColor {
        guard !(isDeleted) else {
            return JVDesign.colors.resolve(usage: .agentForeground).jv_withAlpha(0.5)
        }
        
        switch sender {
        case .client: return JVDesign.colors.resolve(usage: .clientForeground)
        case .agent: return JVDesign.colors.resolve(usage: .agentForeground)
        case .comment: return JVDesign.colors.resolve(usage: .agentForeground)
        case .call: return JVDesign.colors.resolve(usage: .secondaryForeground)
        case .info: return JVDesign.colors.resolve(usage: .agentForeground)
        case .bot: return JVDesign.colors.resolve(usage: .agentForeground)
        case .story: return JVDesign.colors.resolve(usage: .clientForeground)
        case .neutral: return JVDesign.colors.resolve(usage: .clientForeground)
        }
    }
    
    private func generateAudioItem(for message: JVMessage) -> JMTimelineItem {
        guard let media = message.media, let url = media.fullURL ?? media.thumbURL else {
            return generatePlainItem(for: message)
        }
        
        let uid = message.UUID
        let position = obtainItemPosition(for: message)
        let contentKind = detectSenderType(for: message)
        let palette = obtainItemPalette(for: message)
        let isFailure = message.delivery.isFailure
        
        let messageInfo = JMTimelineMessageAudioInfo(
            URL: url,
            title: media.name,
            duration: media.duration.ifPositive(),
            style: _generateAudioItem_style(contentKind: contentKind)
        )
        
        let messageMeta = generateMessageMeta(
            message: message
        )
        
        return JMTimelineMessageItem(
            uid: uid,
            date: message.date,
            layoutValues: generateMessageLayoutValues(),
            logicOptions: (
                message.hasIdentity
                ? [.enableSizeCaching]
                : [.enableSizeCaching, .isVirtual]
            ),
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineMessagePayload(
                kindID: #function,
                sender: obtainItemSender(for: message),
                renderOptions: JMTimelineMessageRenderOptions(
                    position: position
                ),
                provider: provider,
                interactor: interactor,
                regionsGenerator: {
                    let audioRegion = JMTimelineMessageAudioRegion()
                    return [audioRegion]
                },
                regionsPopulator: { [provider, interactor] regions in
                    if let audioRegion = regions.first as? JMTimelineMessageAudioRegion {
                        audioRegion.setup(
                            uid: uid,
                            info: messageInfo,
                            meta: messageMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: position,
                                contentKind: contentKind,
                                outcomingPalette: palette,
                                isQuote: false,
                                entireCanvas: false,
                                isFailure: isFailure
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                }
            )
        )
    }
    
    private func generateVoiceMessageItem(for message: JVMessage) -> JMTimelineItem {
        guard let media = message.media, let url = media.fullURL ?? media.thumbURL else {
            return generatePlainItem(for: message)
        }
        
        let uid = message.UUID
        let position = obtainItemPosition(for: message)
        let contentKind = detectSenderType(for: message)
        let palette = obtainItemPalette(for: message)
        let isFailure = message.delivery.isFailure
        
        let messageInfo = JMTimelineMessageAudioInfo(
            URL: url,
            title: media.name,
            duration: media.duration.ifPositive(),
            style: _generateVoiceItem_style(contentKind: contentKind)
        )
        
        let messageMeta = generateMessageMeta(
            message: message
        )
        
        return JMTimelineMessageItem(
            uid: uid,
            date: message.date,
            layoutValues: generateMessageLayoutValues(),
            logicOptions: (
                message.hasIdentity
                ? [.enableSizeCaching]
                : [.enableSizeCaching, .isVirtual]
            ),
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineMessagePayload(
                kindID: #function,
                sender: obtainItemSender(for: message),
                renderOptions: JMTimelineMessageRenderOptions(
                    position: position
                ),
                provider: provider,
                interactor: interactor,
                regionsGenerator: {
                    let voiceMessageRegion = JMTimelineVoiceMessageRegion()
                    return [voiceMessageRegion]
                },
                regionsPopulator: { [provider, interactor] regions in
                    if let audioRegion = regions.first as? JMTimelineVoiceMessageRegion {
                        audioRegion.setup(
                            uid: uid,
                            info: messageInfo,
                            meta: messageMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: position,
                                contentKind: contentKind,
                                outcomingPalette: palette,
                                isQuote: false,
                                entireCanvas: false,
                                isFailure: isFailure
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                }
            )
        )
    }
    
    private func _generateAudioItem_style(contentKind: ChatTimelineSenderType) -> JMTimelineCompositeAudioStyleExtended {
        switch contentKind {
        case .agent, .comment, .call, .info, .bot, .neutral:
            return JMTimelineCompositeAudioStyleExtended(
                backViewColor: JVDesign.colors.resolve(usage: .audioPlayerBackground),
                buttonTintColor: JVDesign.colors.resolve(usage: .audioPlayerButtonTint),
                buttonBorderColor: JVDesign.colors.resolve(usage: .audioPlayerButtonBorder),
                buttonBackgroundColor: JVDesign.colors.resolve(usage: .audioPlayerButtonBackground),
                minimumTrackColor: JVDesign.colors.resolve(usage: .audioPlayerDuration),
                maximumTrackColor: JVDesign.colors.resolve(usage: .audioPlayerDuration).jv_withAlpha(0.5),
                durationLabelColor: JVDesign.colors.resolve(usage: .audioPlayerDuration)
            )
        case .client, .story:
            return JMTimelineCompositeAudioStyleExtended(
                backViewColor: JVDesign.colors.resolve(usage: .clientBackground),
                buttonTintColor: JVDesign.colors.resolve(alias: .white),
                buttonBorderColor: JVDesign.colors.resolve(alias: .white),
                buttonBackgroundColor: JVDesign.colors.resolve(usage: .clientBackground),
                minimumTrackColor: JVDesign.colors.resolve(alias: .white),
                maximumTrackColor: JVDesign.colors.resolve(alias: .white).jv_withAlpha(0.5),
                durationLabelColor: JVDesign.colors.resolve(alias: .white)
            )
        }
    }
    
    private func _generateVoiceItem_style(contentKind: ChatTimelineSenderType) -> JMTimelineCompositeAudioStyleExtended {
        switch contentKind {
        case .agent, .comment, .call, .info, .bot, .neutral:
            return JMTimelineCompositeAudioStyleExtended(
                backViewColor: JVDesign.colors.resolve(usage: .audioPlayerBackground),
                buttonTintColor: JVDesign.colors.resolve(usage: .audioPlayerButtonTint),
                buttonBorderColor: JVDesign.colors.resolve(usage: .audioPlayerButtonBorder),
                buttonBackgroundColor: JVDesign.colors.resolve(usage: .audioPlayerButtonBackground),
                minimumTrackColor: JVDesign.colors.resolve(usage: .agentBackground).jv_withAlpha(0.5),
                maximumTrackColor: JVDesign.colors.resolve(usage: .agentBackground).jv_withAlpha(0),
                durationLabelColor: JVDesign.colors.resolve(usage: .audioPlayerDuration)
            )
        case .client, .story:
            return JMTimelineCompositeAudioStyleExtended(
                backViewColor: JVDesign.colors.resolve(usage: .clientBackground),
                buttonTintColor: JVDesign.colors.resolve(alias: .white),
                buttonBorderColor: JVDesign.colors.resolve(alias: .white),
                buttonBackgroundColor: JVDesign.colors.resolve(usage: .clientBackground),
                minimumTrackColor: JVDesign.colors.resolve(usage: .clientBackground).jv_withAlpha(0.5),
                maximumTrackColor: JVDesign.colors.resolve(alias: .white).jv_withAlpha(0),
                durationLabelColor: JVDesign.colors.resolve(alias: .white)
            )
        }
    }
    
    private func generateStickerItem(for message: JVMessage) -> JMTimelineItem {
        if let media = message.media, let url = media.fullURL ?? media.thumbURL {
            let messageInfo = JMTimelineMessagePhotoInfo(
                url: url,
                width: Int(media.originalSize.width),
                height: Int(media.originalSize.height),
                contentMode: .scaleAspectFit,
                allowFullscreen: true
            )
            
            let messageMeta = generateMessageMeta(
                message: message
            )
            
            let uid = message.UUID
            let position = obtainItemPosition(for: message)
            let contentKind = detectSenderType(for: message)
            let palette = obtainItemPalette(for: message)
            let isFailure = message.delivery.isFailure
            
            return JMTimelineMessageItem(
                uid: uid,
                date: message.date,
                layoutValues: generateMessageLayoutValues(),
                logicOptions: (
                    message.hasIdentity
                    ? [.enableSizeCaching]
                    : [.enableSizeCaching, .isVirtual]
                ),
                extraActions: obtainItemExtra(for: message),
                payload: JMTimelineMessagePayload(
                    kindID: #function,
                    sender: obtainItemSender(for: message),
                    renderOptions: JMTimelineMessageRenderOptions(
                        position: position
                    ),
                    provider: provider,
                    interactor: interactor,
                    regionsGenerator: {
                        let photoRegion = JMTimelineMessagePhotoRegion()
                        return [photoRegion]
                    },
                    regionsPopulator: { [provider, interactor] regions in
                        if let photoRegion = regions.first as? JMTimelineMessagePhotoRegion {
                            photoRegion.setup(
                                uid: uid,
                                info: messageInfo,
                                meta: messageMeta,
                                options: JMTimelineMessageRegionRenderOptions(
                                    position: position,
                                    contentKind: contentKind,
                                    outcomingPalette: palette,
                                    isQuote: false,
                                    entireCanvas: true,
                                    isFailure: isFailure
                                ),
                                provider: provider,
                                interactor: interactor)
                        }
                    }
                )
            )
        }
        else if let emoji = message.text.jv_oneEmojiString() {
            let messageInfo = JMTimelineMessageEmojiInfo(
                emoji: emoji,
                style: JMTimelineCompositePlainStyle(
                    textColor: .black,
                    identityColor: .black,
                    linkColor: .black,
                    font: obtainEmojiFont(),
                    boldFont: nil,
                    italicsFont: nil,
                    strikeFont: nil,
                    lineHeight: 65,
                    alignment: .natural,
                    underlineStyle: .single,
                    parseMarkdown: false
                )
            )
            
            let messageMeta = generateMessageMeta(
                message: message
            )
            
            let uid = message.UUID
            let position = obtainItemPosition(for: message)
            let palette = obtainItemPalette(for: message)
            let isFailure = message.delivery.isFailure
            
            return JMTimelineMessageItem(
                uid: uid,
                date: message.date,
                layoutValues: generateMessageLayoutValues(),
                logicOptions: (
                    message.hasIdentity
                    ? [.enableSizeCaching]
                    : [.enableSizeCaching, .isVirtual]
                ),
                extraActions: obtainItemExtra(for: message),
                payload: JMTimelineMessagePayload(
                    kindID: #function,
                    sender: obtainItemSender(for: message),
                    renderOptions: JMTimelineMessageRenderOptions(
                        position: position
                    ),
                    provider: provider,
                    interactor: interactor,
                    regionsGenerator: {
                        let emojiRegion = JMTimelineMessageEmojiRegion()
                        return [emojiRegion]
                    },
                    regionsPopulator: { [provider, interactor] regions in
                        if let emojiRegion = regions.first as? JMTimelineMessageEmojiRegion {
                            emojiRegion.setup(
                                uid: uid,
                                info: messageInfo,
                                meta: messageMeta,
                                options: JMTimelineMessageRegionRenderOptions(
                                    position: position,
                                    contentKind: .neutral,
                                    outcomingPalette: palette,
                                    isQuote: false,
                                    entireCanvas: true,
                                    isFailure: isFailure
                                ),
                                provider: provider,
                                interactor: interactor)
                        }
                    }
                )
            )
        }
        else {
            return generatePlainItem(for: message)
        }
    }
    
    private func generateDocumentItem(for message: JVMessage) -> JMTimelineItem {
        guard let media = message.media, let url = media.fullURL ?? media.thumbURL else {
            return generatePlainItem(for: message)
        }
        
        let uid = message.UUID
        let position = obtainItemPosition(for: message)
        let contentKind = detectSenderType(for: message)
        let palette = obtainItemPalette(for: message)
        let isFailure = message.delivery.isFailure
        
        let messageInfo = JMTimelineMediaDocumentInfo(
            URL: url,
            title: media.name,
            dataSize: (
                media.dataSize == .zero
                ? nil
                : Int64(media.dataSize)
            ),
            style: JMTimelineMediaStyle(
                iconTintColor: _generateDocumentItem_iconColor(sender: contentKind),
                titleColor: _generateDocumentItem_textColor(sender: contentKind, isDeleted: message.isDeleted),
                subtitleColor: _generateDocumentItem_textColor(sender: contentKind, isDeleted: message.isDeleted).jv_withAlpha(0.6)
            )
        )
        
        let messageMeta = generateMessageMeta(
            message: message
        )
        
        return JMTimelineMessageItem(
            uid: uid,
            date: message.date,
            layoutValues: generateMessageLayoutValues(),
            logicOptions: (
                message.hasIdentity
                ? [.enableSizeCaching]
                : [.enableSizeCaching, .isVirtual]
            ),
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineMessagePayload(
                kindID: #function,
                sender: obtainItemSender(for: message),
                renderOptions: JMTimelineMessageRenderOptions(
                    position: position
                ),
                provider: provider,
                interactor: interactor,
                regionsGenerator: {
                    let mediaRegion = JMTimelineMessageMediaRegion()
                    return [mediaRegion]
                },
                regionsPopulator: { [provider, interactor] regions in
                    if let mediaRegion = regions.first as? JMTimelineMessageMediaRegion {
                        mediaRegion.setup(
                            uid: uid,
                            info: messageInfo,
                            meta: messageMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: position,
                                contentKind: contentKind,
                                outcomingPalette: palette,
                                isQuote: false,
                                entireCanvas: false,
                                isFailure: isFailure
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                }
            )
        )
    }
    
    private func _generateDocumentItem_iconColor(sender: ChatTimelineSenderType) -> UIColor {
        switch sender {
        case .client: return JVDesign.colors.resolve(usage: .clientBackground)
        case .agent: return JVDesign.colors.resolve(usage: .agentBackground)
        case .comment: return JVDesign.colors.resolve(usage: .agentBackground)
        case .call: return JVDesign.colors.resolve(usage: .agentBackground)
        case .info: return JVDesign.colors.resolve(usage: .agentBackground)
        case .bot: return JVDesign.colors.resolve(usage: .agentBackground)
        case .story: return JVDesign.colors.resolve(usage: .clientBackground)
        case .neutral: return JVDesign.colors.resolve(usage: .agentBackground)
        }
    }
    
    private func _generateDocumentItem_textColor(sender: ChatTimelineSenderType, isDeleted: Bool) -> UIColor {
        guard !(isDeleted) else {
            return JVDesign.colors.resolve(usage: .agentForeground).jv_withAlpha(0.5)
        }
        
        switch sender {
        case .client: return JVDesign.colors.resolve(usage: .clientForeground)
        case .agent: return JVDesign.colors.resolve(usage: .agentForeground)
        case .comment: return JVDesign.colors.resolve(usage: .agentForeground)
        case .call: return JVDesign.colors.resolve(usage: .secondaryForeground)
        case .info: return JVDesign.colors.resolve(usage: .agentForeground)
        case .bot: return JVDesign.colors.resolve(usage: .agentForeground)
        case .story: return JVDesign.colors.resolve(usage: .clientForeground)
        case .neutral: return JVDesign.colors.resolve(usage: .clientForeground)
        }
    }
    
    private func generateCommentItem(for message: JVMessage) -> JMTimelineItem {
        let uid = message.UUID
        let position = obtainItemPosition(for: message)
        let palette = obtainItemPalette(for: message)
        let sender = detectSenderType(for: message)
        let isFailure = message.delivery.isFailure
        
        let messageInfo = JMTimelineMessagePlainInfo(
            text: message.text,
            style: JMTimelineCompositePlainStyle(
                textColor: _generateCommentItem_textColor(sender: sender, isDeleted: message.isDeleted),
                identityColor: JVDesign.colors.resolve(usage: .identityDetectionForeground),
                linkColor: JVDesign.colors.resolve(usage: .linkDetectionForeground),
                font: obtainCommentFont(isDeleted: message.isDeleted),
                boldFont: nil,
                italicsFont: nil,
                strikeFont: nil,
                lineHeight: 22,
                alignment: .natural,
                underlineStyle: .single,
                parseMarkdown: false
            )
        )
        
        let messageMeta = generateMessageMeta(
            message: message
        )
        
        return JMTimelineMessageItem(
            uid: uid,
            date: message.date,
            layoutValues: generateMessageLayoutValues(),
            logicOptions: [.enableSizeCaching],
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineMessagePayload(
                kindID: #function,
                sender: obtainItemSender(for: message),
                renderOptions: JMTimelineMessageRenderOptions(
                    position: position
                ),
                provider: provider,
                interactor: interactor,
                regionsGenerator: {
                    let plainRegion = JMTimelineMessagePlainRegion()
                    return [plainRegion]
                },
                regionsPopulator: { [provider, interactor] regions in
                    if let plainRegion = regions.first as? JMTimelineMessagePlainRegion {
                        plainRegion.setup(
                            uid: uid,
                            info: messageInfo,
                            meta: messageMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: position,
                                contentKind: .comment,
                                outcomingPalette: palette,
                                isQuote: false,
                                entireCanvas: false,
                                isFailure: isFailure
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                }
            )
        )
    }
    
    private func _generateCommentItem_textColor(sender: ChatTimelineSenderType, isDeleted: Bool) -> UIColor {
        if isDeleted {
            return JVDesign.colors.resolve(usage: .agentForeground).jv_withAlpha(0.5)
        }
        else {
            return JVDesign.colors.resolve(usage: .agentForeground)
        }
    }
    
    private func generateLocationItem(for message: JVMessage) -> JMTimelineItem {
        guard let media = message.media, let coordinate = media.coordinate else {
            return generatePlainItem(for: message)
        }
        
        let messageInfo = JMTimelineMessageLocationInfo(
            coordinate: coordinate
        )
        
        let messageMeta = generateMessageMeta(
            message: message
        )
        
        let uid = message.UUID
        let position = obtainItemPosition(for: message)
        let contentKind = detectSenderType(for: message)
        let palette = obtainItemPalette(for: message)
        let isFailure = message.delivery.isFailure
        
        return JMTimelineMessageItem(
            uid: uid,
            date: message.date,
            layoutValues: generateMessageLayoutValues(),
            logicOptions: [.enableSizeCaching],
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineMessagePayload(
                kindID: #function,
                sender: obtainItemSender(for: message),
                renderOptions: JMTimelineMessageRenderOptions(
                    position: position
                ),
                provider: provider,
                interactor: interactor,
                regionsGenerator: {
                    let locationRegion = JMTimelineMessageLocationRegion()
                    return [locationRegion]
                },
                regionsPopulator: { [provider, interactor] regions in
                    if let locationRegion = regions.first as? JMTimelineMessageLocationRegion {
                        locationRegion.setup(
                            uid: uid,
                            info: messageInfo,
                            meta: messageMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: position,
                                contentKind: contentKind,
                                outcomingPalette: palette,
                                isQuote: false,
                                entireCanvas: false,
                                isFailure: isFailure
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                }
            )
        )
    }
    
    private func generateContactItem(for message: JVMessage) -> JMTimelineItem {
        guard let media = message.media, let name = media.name, let phone = media.phone else {
            return generatePlainItem(for: message)
        }
        
        let uid = message.UUID
        let position = obtainItemPosition(for: message)
        let contentKind = detectSenderType(for: message)
        let palette = obtainItemPalette(for: message)
        let isFailure = message.delivery.isFailure
        
        let messageInfo = JMTimelineMediaContactInfo(
            name: name,
            phone: phone,
            style: JMTimelineMediaStyle(
                iconTintColor: _generateContactItem_iconColor(sender: contentKind),
                titleColor: _generateContactItem_textColor(sender: contentKind, isDeleted: message.isDeleted),
                subtitleColor: _generateContactItem_textColor(sender: contentKind, isDeleted: message.isDeleted).jv_withAlpha(0.6)
            )
        )
        
        let messageMeta = generateMessageMeta(
            message: message
        )
        
        return JMTimelineMessageItem(
            uid: uid,
            date: message.date,
            layoutValues: generateMessageLayoutValues(),
            logicOptions: [.enableSizeCaching],
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineMessagePayload(
                kindID: #function,
                sender: obtainItemSender(for: message),
                renderOptions: JMTimelineMessageRenderOptions(
                    position: position
                ),
                provider: provider,
                interactor: interactor,
                regionsGenerator: {
                    let mediaRegion = JMTimelineMessageMediaRegion()
                    return [mediaRegion]
                },
                regionsPopulator: { [provider, interactor] regions in
                    if let mediaRegion = regions.first as? JMTimelineMessageMediaRegion {
                        mediaRegion.setup(
                            uid: uid,
                            info: messageInfo,
                            meta: messageMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: position,
                                contentKind: contentKind,
                                outcomingPalette: palette,
                                isQuote: false,
                                entireCanvas: false,
                                isFailure: isFailure
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                }
            )
        )
    }
    
    private func _generateContactItem_iconColor(sender: ChatTimelineSenderType) -> UIColor {
        switch sender {
        case .client: return JVDesign.colors.resolve(usage: .clientBackground)
        case .agent: return JVDesign.colors.resolve(usage: .agentBackground)
        case .comment: return JVDesign.colors.resolve(usage: .agentBackground)
        case .call: return JVDesign.colors.resolve(usage: .agentBackground)
        case .info: return JVDesign.colors.resolve(usage: .agentBackground)
        case .bot: return JVDesign.colors.resolve(usage: .agentBackground)
        case .story: return JVDesign.colors.resolve(usage: .clientBackground)
        case .neutral: return JVDesign.colors.resolve(usage: .agentBackground)
        }
    }
    
    private func _generateContactItem_textColor(sender: ChatTimelineSenderType, isDeleted: Bool) -> UIColor {
        guard !(isDeleted) else {
            return JVDesign.colors.resolve(usage: .agentForeground).jv_withAlpha(0.5)
        }
        
        switch sender {
        case .client: return JVDesign.colors.resolve(usage: .clientForeground)
        case .agent: return JVDesign.colors.resolve(usage: .agentForeground)
        case .comment: return JVDesign.colors.resolve(usage: .agentForeground)
        case .call: return JVDesign.colors.resolve(usage: .secondaryForeground)
        case .info: return JVDesign.colors.resolve(usage: .agentForeground)
        case .bot: return JVDesign.colors.resolve(usage: .agentForeground)
        case .story: return JVDesign.colors.resolve(usage: .clientForeground)
        case .neutral: return JVDesign.colors.resolve(usage: .clientForeground)
        }
    }
    
    private func generateCallItem(for message: JVMessage) -> JMTimelineItem {
        guard let call = message.call else {
            abort()
        }
        
        let stateIcon: UIImage?
        switch call.type {
        case .outgoing where call.isFailed:
            stateIcon = UIImage(named: "call_out_fail", in: Bundle(for: JVDesign.self), compatibleWith: nil)
        case .outgoing:
            stateIcon = UIImage(named: "call_out", in: Bundle(for: JVDesign.self), compatibleWith: nil)
        case .callback where call.isFailed:
            stateIcon = UIImage(named: "call_out_fail", in: Bundle(for: JVDesign.self), compatibleWith: nil)
        case .callback:
            stateIcon = UIImage(named: "call_out", in: Bundle(for: JVDesign.self), compatibleWith: nil)
        case .incoming where call.isFailed:
            stateIcon = UIImage(named: "call_in_fail", in: Bundle(for: JVDesign.self), compatibleWith: nil)
        default:
            stateIcon = UIImage(named: "call_in", in: Bundle(for: JVDesign.self), compatibleWith: nil)
        }
        
        let stateTitle: String
        if call.type == .incoming {
            if call.isFailed {
                stateTitle = loc["Message.Call.Status.Missed"]
            }
            else {
                stateTitle = loc["Message.Call.Type.Incoming"]
            }
        }
        else if call.type == .outgoing {
            if call.isFailed {
                stateTitle = loc["Message.Call.Status.Failed"]
            }
            else {
                stateTitle = loc["Message.Call.Type.Outgoing"]
            }
        }
        else if call.type == .callback {
            if call.isFailed {
                stateTitle = loc["Message.Call.Callback.Missed"]
            }
            else {
                stateTitle = loc["Message.Call.Type.Callback"]
            }
        }
        else {
            stateTitle = String()
        }
        
        let duration: TimeInterval?
#if ENV_MOCK
        duration = 138
#else
        duration = nil
#endif
        
        let messageInfo = JMTimelineMessageCallInfo(
            repic: JMRepicItem(
                backgroundColor: nil,
                source: stateIcon.flatMap(JMRepicItemSource.exact) ?? .empty,
                scale: 1.0,
                clipping: .disabled),
            state: stateTitle,
            phone: call.phone.flatMap(provider.formattedPhoneNumber),
            recordURL: call.recordURL,
            duration: duration
        )
        
        let messageMeta = generateMessageMeta(
            message: message
        )
        
        if let _ = call.recordURL {
            let uid = message.UUID
            let position = obtainItemPosition(for: message)
            let contentKind = detectSenderType(for: message)
            let palette = obtainItemPalette(for: message)
            let isFailure = message.delivery.isFailure
            
            return JMTimelineMessageItem(
                uid: uid,
                date: message.date,
                layoutValues: generateMessageLayoutValues(),
                logicOptions: [.enableSizeCaching],
                extraActions: obtainItemExtra(for: message),
                payload: JMTimelineMessagePayload(
                    kindID: #function + "playable",
                    sender: obtainItemSender(for: message),
                    renderOptions: JMTimelineMessageRenderOptions(
                        position: position
                    ),
                    provider: provider,
                    interactor: interactor,
                    regionsGenerator: {
                        let callRegion = JMTimelineMessagePlayableCallRegion()
                        return [callRegion]
                    },
                    regionsPopulator: { [provider, interactor] regions in
                        if let callRegion = regions.first as? JMTimelineMessagePlayableCallRegion {
                            callRegion.setup(
                                uid: uid,
                                info: messageInfo,
                                meta: messageMeta,
                                options: JMTimelineMessageRegionRenderOptions(
                                    position: position,
                                    contentKind: contentKind,
                                    outcomingPalette: palette,
                                    isQuote: false,
                                    entireCanvas: false,
                                    isFailure: isFailure
                                ),
                                provider: provider,
                                interactor: interactor)
                        }
                    }
                )
            )
        }
        else {
            let uid = message.UUID
            let position = obtainItemPosition(for: message)
            let contentKind = detectSenderType(for: message)
            let palette = obtainItemPalette(for: message)
            let isFailure = message.delivery.isFailure
            
            return JMTimelineMessageItem(
                uid: uid,
                date: message.date,
                layoutValues: generateMessageLayoutValues(),
                logicOptions: [.enableSizeCaching],
                extraActions: obtainItemExtra(for: message),
                payload: JMTimelineMessagePayload(
                    kindID: #function + "recordless",
                    sender: obtainItemSender(for: message),
                    renderOptions: JMTimelineMessageRenderOptions(
                        position: position
                    ),
                    provider: provider,
                    interactor: interactor,
                    regionsGenerator: {
                        let callRegion = JMTimelineMessageRecordlessCallRegion()
                        return [callRegion]
                    },
                    regionsPopulator: { [provider, interactor] regions in
                        if let callRegion = regions.first as? JMTimelineMessageRecordlessCallRegion {
                            callRegion.setup(
                                uid: uid,
                                info: messageInfo,
                                meta: messageMeta,
                                options: JMTimelineMessageRegionRenderOptions(
                                    position: position,
                                    contentKind: contentKind,
                                    outcomingPalette: palette,
                                    isQuote: false,
                                    entireCanvas: false,
                                    isFailure: isFailure
                                ),
                                provider: provider,
                                interactor: interactor)
                        }
                    }
                )
            )
        }
    }
    
    private func generateEmailItem(for message: JVMessage) -> JMTimelineItem {
        guard
            case let .email(from, to, subject, text) = message.content,
            let _ = message.senderClient
        else {
            return generatePlainItem(for: message)
        }
        
        let uid = message.UUID
        let position = obtainItemPosition(for: message)
        let contentKind = detectSenderType(for: message)
        let palette = obtainItemPalette(for: message)
        let isFailure = message.delivery.isFailure
        
        let messageInfo = JMTimelineMessageEmailInfo(
            headers: [
                JMTimelineCompositePair(
                    caption: loc["Message.Email.To"] + ":",
                    value: to
                ),
                JMTimelineCompositePair(
                    caption: loc["Message.Email.From"] + ":",
                    value: from
                ),
                JMTimelineCompositePair(
                    caption: loc["Message.Email.Subject"] + ":",
                    value: subject
                )
            ],
            message: text,
            style: JMTimelineCompositePlainStyle(
                textColor: _generateEmailItem_textColor(sender: contentKind),
                identityColor: _generateEmailItem_identityColor(sender: contentKind),
                linkColor: _generateEmailItem_linkColor(sender: contentKind),
                font: JVDesign.fonts.resolve(.regular(16), scaling: .callout),
                boldFont: nil,
                italicsFont: nil,
                strikeFont: nil,
                lineHeight: 22,
                alignment: .natural,
                underlineStyle: .single,
                parseMarkdown: true
            )
        )
        
        let messageMeta = generateMessageMeta(
            message: message
        )
        
        return JMTimelineMessageItem(
            uid: uid,
            date: message.date,
            layoutValues: generateMessageLayoutValues(),
            logicOptions: [.enableSizeCaching],
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineMessagePayload(
                kindID: #function,
                sender: obtainItemSender(for: message),
                renderOptions: JMTimelineMessageRenderOptions(
                    position: position
                ),
                provider: provider,
                interactor: interactor,
                regionsGenerator: {
                    let emailRegion = JMTimelineMessageEmailRegion()
                    return [emailRegion]
                },
                regionsPopulator: { [provider, interactor] regions in
                    if let emailRegion = regions.first as? JMTimelineMessageEmailRegion {
                        emailRegion.setup(
                            uid: uid,
                            info: messageInfo,
                            meta: messageMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: position,
                                contentKind: contentKind,
                                outcomingPalette: palette,
                                isQuote: false,
                                entireCanvas: false,
                                isFailure: isFailure
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                }
            )
        )
    }
    
    private func _generateEmailItem_textColor(sender: ChatTimelineSenderType) -> UIColor {
        switch sender {
        case .client: return JVDesign.colors.resolve(usage: .clientForeground)
        case .agent: return JVDesign.colors.resolve(usage: .agentForeground)
        case .comment: return JVDesign.colors.resolve(usage: .agentForeground)
        case .call: return JVDesign.colors.resolve(usage: .secondaryForeground)
        case .info: return JVDesign.colors.resolve(usage: .agentForeground)
        case .bot: return JVDesign.colors.resolve(usage: .agentForeground)
        case .story: return JVDesign.colors.resolve(usage: .clientForeground)
        case .neutral: return JVDesign.colors.resolve(usage: .clientForeground)
        }
    }
    
    private func _generateEmailItem_identityColor(sender: ChatTimelineSenderType) -> UIColor {
        switch sender {
        case .client: return JVDesign.colors.resolve(usage: .clientIdentityForeground)
        case .agent: return JVDesign.colors.resolve(usage: .agentIdentityForeground)
        case .comment: return JVDesign.colors.resolve(usage: .agentIdentityForeground)
        case .call: return JVDesign.colors.resolve(usage: .identityDetectionForeground)
        case .info: return JVDesign.colors.resolve(usage: .identityDetectionForeground)
        case .bot: return JVDesign.colors.resolve(usage: .agentIdentityForeground)
        case .story: return JVDesign.colors.resolve(usage: .clientIdentityForeground)
        case .neutral: return JVDesign.colors.resolve(usage: .clientIdentityForeground)
        }
    }
    
    private func _generateEmailItem_linkColor(sender: ChatTimelineSenderType) -> UIColor {
        switch sender {
        case .client: return JVDesign.colors.resolve(usage: .clientLinkForeground)
        case .agent: return JVDesign.colors.resolve(usage: .agentLinkForeground)
        case .comment: return JVDesign.colors.resolve(usage: .agentLinkForeground)
        case .call: return JVDesign.colors.resolve(usage: .linkDetectionForeground)
        case .info: return JVDesign.colors.resolve(usage: .linkDetectionForeground)
        case .bot: return JVDesign.colors.resolve(usage: .agentLinkForeground)
        case .story: return JVDesign.colors.resolve(usage: .clientLinkForeground)
        case .neutral: return JVDesign.colors.resolve(usage: .clientLinkForeground)
        }
    }
    
    private func generateConferenceItem(for message: JVMessage) -> JMTimelineItem {
        guard case .conference(let conference) = message.content else {
            return generatePlainItem(for: message)
        }
        
        let messageInfo = JMTimelineMessageConferenceInfo(
            repic: JMRepicItem(
                backgroundColor: nil,
                source: .named(asset: "conference_jazz", template: false),
                scale: 1.0,
                clipping: .dual
            ),
            caption: loc["Conference.Description"],
            button: loc["Conference.Join"],
            url: conference.url
        )
        
        let messageMeta = generateMessageMeta(
            message: message
        )
        
        if let _ = conference.url {
            let uid = message.UUID
            let position = obtainItemPosition(for: message)
            let contentKind = detectSenderType(for: message)
            let palette = obtainItemPalette(for: message)
            let isFailure = message.delivery.isFailure
            
            return JMTimelineMessageItem(
                uid: uid,
                date: message.date,
                layoutValues: generateMessageLayoutValues(),
                logicOptions: [.enableSizeCaching],
                extraActions: obtainItemExtra(for: message),
                payload: JMTimelineMessagePayload(
                    kindID: #function + "joinable",
                    sender: obtainItemSender(for: message),
                    renderOptions: JMTimelineMessageRenderOptions(
                        position: position
                    ),
                    provider: provider,
                    interactor: interactor,
                    regionsGenerator: {
                        let conferenceRegion = JMTimelineMessageJoinableConferenceRegion()
                        return [conferenceRegion]
                    },
                    regionsPopulator: { [provider, interactor] regions in
                        if let conferenceRegion = regions.first as? JMTimelineMessageJoinableConferenceRegion {
                            conferenceRegion.setup(
                                uid: uid,
                                info: messageInfo,
                                meta: messageMeta,
                                options: JMTimelineMessageRegionRenderOptions(
                                    position: position,
                                    contentKind: contentKind,
                                    outcomingPalette: palette,
                                    isQuote: false,
                                    entireCanvas: false,
                                    isFailure: isFailure
                                ),
                                provider: provider,
                                interactor: interactor)
                        }
                    }
                )
            )
        }
        else {
            let uid = message.UUID
            let position = obtainItemPosition(for: message)
            let contentKind = detectSenderType(for: message)
            let palette = obtainItemPalette(for: message)
            let isFailure = message.delivery.isFailure
            
            return JMTimelineMessageItem(
                uid: uid,
                date: message.date,
                layoutValues: generateMessageLayoutValues(),
                logicOptions: [.enableSizeCaching],
                extraActions: obtainItemExtra(for: message),
                payload: JMTimelineMessagePayload(
                    kindID: #function + "finished",
                    sender: obtainItemSender(for: message),
                    renderOptions: JMTimelineMessageRenderOptions(
                        position: position
                    ),
                    provider: provider,
                    interactor: interactor,
                    regionsGenerator: {
                        let conferenceRegion = JMTimelineFinishedConferenceRegion()
                        return [conferenceRegion]
                    },
                    regionsPopulator: { [provider, interactor] regions in
                        if let conferenceRegion = regions.first as? JMTimelineFinishedConferenceRegion {
                            conferenceRegion.setup(
                                uid: uid,
                                info: messageInfo,
                                meta: messageMeta,
                                options: JMTimelineMessageRegionRenderOptions(
                                    position: position,
                                    contentKind: contentKind,
                                    outcomingPalette: palette,
                                    isQuote: false,
                                    entireCanvas: false,
                                    isFailure: isFailure
                                ),
                                provider: provider,
                                interactor: interactor)
                        }
                    }
                )
            )
        }
    }
    
    private func generateStoryItem(for message: JVMessage) -> JMTimelineItem {
        guard case .story(let story) = message.content else {
            preconditionFailure()
        }
        
        if let _ = story.text.jv_valuable {
            return _generateStoryReplyItem(for: message, story: story)
        }
        else {
            return _generateStoryMentionItem(for: message, story: story)
        }
    }
    
    private func _generateStoryReplyItem(for message: JVMessage, story: JVMessageBodyStory) -> JMTimelineItem {
        guard let url = story.file?.absoluteURL else {
            preconditionFailure()
        }
        
        let uid = message.UUID
        let position = obtainItemPosition(for: message)
        let contentKind = detectSenderType(for: message)
        let palette = obtainItemPalette(for: message)
        let isFailure = message.delivery.isFailure
        
        let tooltipInfo = JMTimelineMessagePlainInfo(
            text: loc["Message.Instagram.Reply"],
            style: JMTimelineCompositePlainStyle(
                textColor: JVDesign.colors.resolve(usage: .secondaryForeground),
                identityColor: JVDesign.colors.resolve(usage: .identityDetectionForeground),
                linkColor: JVDesign.colors.resolve(usage: .linkDetectionForeground),
                font: obtainTooltipFont(),
                boldFont: nil,
                italicsFont: nil,
                strikeFont: nil,
                lineHeight: 20,
                alignment: .natural,
                underlineStyle: .single,
                parseMarkdown: false
            )
        )
        
        let storyInfo = JMTimelineMessagePhotoInfo(
            url: url,
            width: Int(UIScreen.main.bounds.width * 0.4),
            height: Int(UIScreen.main.bounds.width * 0.62),
            contentMode: .scaleAspectFill,
            allowFullscreen: true
        )
        
        let plainInfo = JMTimelineMessagePlainInfo(
            text: story.text,
            style: JMTimelineCompositePlainStyle(
                textColor: _generatePlainItem_textColor(sender: contentKind, isDeleted: message.isDeleted),
                identityColor: JVDesign.colors.resolve(usage: .identityDetectionForeground),
                linkColor: JVDesign.colors.resolve(usage: .linkDetectionForeground),
                font: obtainCommentFont(isDeleted: message.isDeleted),
                boldFont: nil,
                italicsFont: nil,
                strikeFont: nil,
                lineHeight: 22,
                alignment: .natural,
                underlineStyle: .single,
                parseMarkdown: false
            )
        )
        
        let emojiInfo = JMTimelineMessageEmojiInfo(
            emoji: story.text.jv_oneEmojiString() ?? String(),
            style: JMTimelineCompositePlainStyle(
                textColor: .black,
                identityColor: .black,
                linkColor: .black,
                font: obtainEmojiFont(),
                boldFont: nil,
                italicsFont: nil,
                strikeFont: nil,
                lineHeight: 65,
                alignment: .natural,
                underlineStyle: .single,
                parseMarkdown: false
            )
        )
        
        let plainMeta = generateMessageMeta(
            message: message
        )
        
        let isEmoji = !(emojiInfo.emoji.isEmpty)
        return JMTimelineMessageItem(
            uid: uid,
            date: message.date,
            layoutValues: generateMessageLayoutValues(),
            logicOptions: [.enableSizeCaching],
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineMessagePayload(
                kindID: #function + (isEmoji ? "emoji" : "plain"),
                sender: obtainItemSender(for: message),
                renderOptions: JMTimelineMessageRenderOptions(
                    position: position
                ),
                provider: provider,
                interactor: interactor,
                regionsGenerator: {
                    let tooltipRegion = JMTimelineTooltipRegion()
                    let storyRegion = JMTimelineMessageStoryReplyRegion()
                    
                    if isEmoji {
                        let emojiRegion = JMTimelineMessageEmojiRegion()
                        return [tooltipRegion, storyRegion, emojiRegion]
                    }
                    else {
                        let plainRegion = JMTimelineMessagePlainRegion()
                        return [tooltipRegion, storyRegion, plainRegion]
                    }
                },
                regionsPopulator: { [provider, interactor] regions in
                    if let tooltipRegion = regions[0] as? JMTimelineTooltipRegion {
                        tooltipRegion.setup(
                            uid: uid,
                            info: tooltipInfo,
                            meta: plainMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: position,
                                contentKind: .neutral,
                                outcomingPalette: palette,
                                isQuote: false,
                                entireCanvas: true,
                                isFailure: false
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                    
                    if let storyRegion = regions[1] as? JMTimelineMessageStoryReplyRegion {
                        storyRegion.setup(
                            uid: uid,
                            info: storyInfo,
                            meta: plainMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: position,
                                contentKind: .story,
                                outcomingPalette: palette,
                                isQuote: true,
                                entireCanvas: true,
                                isFailure: false
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                    
                    if let plainRegion = regions[2] as? JMTimelineMessagePlainRegion {
                        plainRegion.setup(
                            uid: uid,
                            info: plainInfo,
                            meta: plainMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: position,
                                contentKind: contentKind,
                                outcomingPalette: palette,
                                isQuote: false,
                                entireCanvas: false,
                                isFailure: isFailure
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                    else if let emojiRegion = regions[2] as? JMTimelineMessageEmojiRegion {
                        emojiRegion.setup(
                            uid: uid,
                            info: emojiInfo,
                            meta: plainMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: position,
                                contentKind: .neutral,
                                outcomingPalette: palette,
                                isQuote: false,
                                entireCanvas: true,
                                isFailure: isFailure
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                }
            )
        )
    }
    
    private func _generateStoryMentionItem(for message: JVMessage, story: JVMessageBodyStory) -> JMTimelineItem {
        guard let url = story.file?.absoluteURL else {
            preconditionFailure()
        }
        
        let uid = message.UUID
        let position = obtainItemPosition(for: message)
        let palette = obtainItemPalette(for: message)
        
        let tooltipInfo = JMTimelineMessagePlainInfo(
            text: loc["Message.Instagram.Mention"],
            style: JMTimelineCompositePlainStyle(
                textColor: JVDesign.colors.resolve(usage: .secondaryForeground),
                identityColor: JVDesign.colors.resolve(usage: .identityDetectionForeground),
                linkColor: JVDesign.colors.resolve(usage: .linkDetectionForeground),
                font: obtainTooltipFont(),
                boldFont: nil,
                italicsFont: nil,
                strikeFont: nil,
                lineHeight: 20,
                alignment: .natural,
                underlineStyle: .single,
                parseMarkdown: false
            )
        )
        
        let storyInfo = JMTimelineMessagePhotoInfo(
            url: url,
            width: Int(UIScreen.main.bounds.width * 0.4),
            height: Int(UIScreen.main.bounds.width * 0.62),
            contentMode: .scaleAspectFill,
            allowFullscreen: true
        )
        
        let plainMeta = generateMessageMeta(
            message: message
        )
        
        return JMTimelineMessageItem(
            uid: uid,
            date: message.date,
            layoutValues: generateMessageLayoutValues(),
            logicOptions: [.enableSizeCaching],
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineMessagePayload(
                kindID: #function,
                sender: obtainItemSender(for: message),
                renderOptions: JMTimelineMessageRenderOptions(
                    position: position
                ),
                provider: provider,
                interactor: interactor,
                regionsGenerator: {
                    let tooltipRegion = JMTimelineTooltipRegion()
                    let storyRegion = JMTimelineMessageStoryMentionRegion()
                    return [tooltipRegion, storyRegion]
                },
                regionsPopulator: { [provider, interactor] regions in
                    if let tooltipRegion = regions[0] as? JMTimelineTooltipRegion {
                        tooltipRegion.setup(
                            uid: uid,
                            info: tooltipInfo,
                            meta: plainMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: position,
                                contentKind: .neutral,
                                outcomingPalette: palette,
                                isQuote: false,
                                entireCanvas: true,
                                isFailure: false
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                    
                    if let storyRegion = regions[1] as? JMTimelineMessageStoryMentionRegion {
                        storyRegion.setup(
                            uid: uid,
                            info: storyInfo,
                            meta: plainMeta,
                            options: JMTimelineMessageRegionRenderOptions(
                                position: position,
                                contentKind: .story,
                                outcomingPalette: palette,
                                isQuote: true,
                                entireCanvas: true,
                                isFailure: false
                            ),
                            provider: provider,
                            interactor: interactor)
                    }
                }
            )
        )
    }
    
    private func generateReminderItem(for message: JVMessage) -> JMTimelineItem {
        guard let reminder = message.task else {
            return generateSystemItem(for: message)
        }
        
        guard let object = databaseDriver.object(JVTask.self, primaryId: reminder.taskID) else {
            return generateSystemItem(for: message)
        }
        
        guard message.taskStatus == .fired, object.status == .fired else {
            return generateSystemItem(for: message)
        }
        
        return JMTimelineSystemItem(
            uid: message.UUID,
            date: message.date,
            layoutValues: generateMessageLayoutValues(),
            logicOptions: [],
            extraActions: obtainItemExtra(for: message),
            payload: JMTimelineSystemInfo(
                icon: message.contextImageURL(
                    transparent: false
                ),
                text: systemMessagingService.generatePreviewPlain(
                    isGroup: isGroup,
                    message: message),
                style: _generateSystemItem_style(
                    font: obtainMediumSystemFont(),
                    textColor: .primaryForeground,
                    alignment: .natural
                ),
                interactiveID: message.interactiveID,
                provider: provider,
                interactor: interactor,
                buttons: [
                    JMTimelineSystemButtonMeta(
                        ID: ChatTimelineActionID.reminderComplete.rawValue,
                        title: loc["Reminder.CompleteAction"]
                    )
                ]
            )
        )
    }
    
    private func obtainItemDelivery(for message: JVMessage) -> JMTimelineItemDelivery {
        if disablingOptions.contains(.delivery) {
            return .hidden
        }
        
        switch message.delivery {
        case .none:
            return .hidden
            
        case .sending:
            return .hidden
            
        case .failed:
            return .failed
            
        case .status(let status):
            switch status {
            case .queued:
                return .queued
            case .sent:
                return .sent
            case .delivered:
                return .delivered
            case .seen:
                return .seen
            case .historic:
                return .hidden
            }
        }
    }
    
    private func obtainItemPosition(for message: JVMessage) -> JMTimelineItemPosition {
        if let _ = message.call {
            return .left
        }
        else if let agent = message.senderAgent, agent.isMe {
            return .right
        }
        else if let agent = message.senderAgent {
            return userContext.isPerson(ofKind: "agent", withID: agent.ID) ? .right : .left
        }
        else if let client = message.senderClient {
            return userContext.isPerson(ofKind: "client", withID: client.ID) ? .right : .left
        }
        else {
            return .left
        }
    }
    
    private func obtainItemPalette(for message: JVMessage) -> JMTimelineMessagePalette? {
        guard let outcomingPalette = outcomingPalette
        else {
            return nil
        }
        
        switch message.content {
        case .bot:
            break
        case _ where obtainItemPosition(for: message) != .right:
            return nil
        default:
            break
        }
        
        return JMTimelineMessagePalette(
            backgroundColor: outcomingPalette.backgroundColor,
            foregroundColor: outcomingPalette.foregroundColor,
            buttonsTintColor: outcomingPalette.buttonsTintColor
        )
    }
    
    private func obtainItemSender(for message: JVMessage) -> JMTimelineItemSender {
        if let _ = message.call, let _ = message.client {
            if let agent = message.senderAgent {
                let ID = agent.hashedID
                let icon = agent.repicItem(transparent: false, scale: nil)
                let name = agent.displayName(kind: displayNameKind)
                return JMTimelineItemSender(
                    ID: ID,
                    icon: icon,
                    name: name,
                    mark: nil,
                    style: _obtainItemSender_style(contentKind: .agent)
                )
            }
            else {
                return JMTimelineItemSender(
                    ID: noneSenderUUID,
                    icon: nil,
                    name: nil,
                    mark: nil,
                    style: _obtainItemSender_style(contentKind: .neutral)
                )
            }
        }
        else if let _ = message.order, let client = message.client {
            let ID = client.hashedID
            let icon = client.repicItem(transparent: false, scale: nil)
            return JMTimelineItemSender(
                ID: ID,
                icon: icon,
                name: nil,
                mark: nil,
                style: _obtainItemSender_style(contentKind: .client)
            )
        }
        else if let bot = message.senderBot {
            return JMTimelineItemSender(
                ID: bot.hashedID,
                icon: bot.repicItem(transparent: false, scale: nil),
                name: bot.displayName(kind: displayNameKind),
                mark: loc["Message.Sender.Bot"],
                style: _obtainItemSender_style(contentKind: .bot)
            )
        }
        else if let agent = message.senderAgent {
            if agent.ID > 0 {
                let icon = agent.isMe ? nil : agent.repicItem(transparent: false, scale: nil)
                let name = agent.displayName(kind: displayNameKind)
                return JMTimelineItemSender(
                    ID: agent.hashedID,
                    icon: icon,
                    name: name,
                    mark: nil,
                    style: _obtainItemSender_style(contentKind: .agent)
                )
            }
            else if agent.ID < 0 {
                return JMTimelineItemSender(
                    ID: agent.hashedID,
                    icon: JMRepicItem(
                        backgroundColor: nil,
                        source: .avatar(
                            URL: agent.m_avatar_link.flatMap(URL.init),
                            image: UIImage(named: "avatar_bot", in: .jv_shared, compatibleWith: nil),
                            color: nil,
                            transparent: false
                        ),
                        scale: 1.0,
                        clipping: .dual
                    ),
                    name: agent.displayName(kind: displayNameKind).jv_valuable ?? loc["Message.Sender.Bot"],
                    mark: loc["Message.Sender.Bot"],
                    style: _obtainItemSender_style(contentKind: .bot)
                )
            }
            else {
                return JMTimelineItemSender(
                    ID: agent.hashedID,
                    icon: nil,
                    name: nil,
                    mark: nil,
                    style: _obtainItemSender_style(contentKind: .neutral)
                )
            }
        }
        else if let client = message.senderClient {
            let ID = client.hashedID
            
            if let _ = message.media?.story {
                let icon = client.repicItem(transparent: false, scale: nil)
                return JMTimelineItemSender(
                    ID: UUID().uuidString,
                    icon: icon,
                    name: nil,
                    mark: nil,
                    style: _obtainItemSender_style(contentKind: .client)
                )
            }
            else if disablingOptions.contains(.clientUserpic) {
                return JMTimelineItemSender(
                    ID: ID,
                    icon: nil,
                    name: nil,
                    mark: nil,
                    style: _obtainItemSender_style(contentKind: .neutral)
                )
            }
            else {
                let icon = client.repicItem(transparent: false, scale: nil)
                return JMTimelineItemSender(
                    ID: ID,
                    icon: icon,
                    name: nil,
                    mark: nil,
                    style: _obtainItemSender_style(contentKind: .client)
                )
            }
        }
        else {
            return JMTimelineItemSender(
                ID: noneSenderUUID,
                icon: nil,
                name: nil,
                mark: nil,
                style: _obtainItemSender_style(contentKind: .neutral)
            )
        }
    }
    
    private func _obtainItemSender_style(contentKind: ChatTimelineSenderType) -> JMTimelineMessageSenderStyle {
        switch contentKind {
        case .client, .story:
            return JMTimelineMessageSenderStyle(
                backgroundColor: .clear,
                foregroundColor: JVDesign.colors.resolve(usage: .secondaryForeground),
                font: obtainSenderFont(),
                padding: .zero,
                corner: 0
            )
            
        case .agent, .comment, .info, .bot:
            return JMTimelineMessageSenderStyle(
                backgroundColor: .clear,
                foregroundColor: JVDesign.colors.resolve(usage: .secondaryForeground),
                font: obtainSenderFont(),
                padding: .zero,
                corner: 0
            )
            
        case .call:
            return JMTimelineMessageSenderStyle(
                backgroundColor: JVDesign.colors.resolve(usage: .badgeBackground),
                foregroundColor: JVDesign.colors.resolve(usage: .oppositeForeground),
                font: obtainSenderFont(),
                padding: .zero,
                corner: 4
            )
            
        case .neutral:
            return JMTimelineMessageSenderStyle(
                backgroundColor: UIColor.clear,
                foregroundColor: UIColor.clear,
                font: obtainSenderFont(),
                padding: .zero,
                corner: 0
            )
        }
    }
    
    private func obtainItemExtra(for message: JVMessage) -> JMTimelineExtraActions {
        let reactions = message.reactions
        
        guard
            !(reactions.isEmpty),
            !(message.isDeleted)
        else { return JMTimelineExtraActions(reactions: [], actions: []) }
        
        return JMTimelineExtraActions(
            reactions: reactions.map { reaction in
                JMTimelineReactionMeta(
                    emoji: reaction.emoji,
                    number: reaction.reactors.count,
                    participated: reaction.reactors.contains(where: { userContext.isPerson(ofKind: $0.subjectKind, withID: $0.subjectID) })
                )
            },
            actions: (reactions.isEmpty
                      ? []
                      : [JMTimelineActionMeta(ID: String(), icon: UIImage(named: "add_emoji", in: Bundle(for: JVDesign.self), compatibleWith: nil) ?? UIImage())]
                     )
        )
    }
    
    private func detectSenderType(for message: JVMessage) -> ChatTimelineSenderType {
        if let _ = message.call {
            return .call
        }
        else if let _ = message.order {
            return .info
        }
        else if case .order = message.content {
            return .agent
        }
        else if case .proactive = message.content {
            return .agent
        }
        else if case .offline = message.content {
            return .agent
        }
        else if case .conference = message.content {
            return .call
        }
        else if let _ = message.senderAgent {
            if case .photo = message.content {
                return .neutral
            }
            else {
                return .agent
            }
        }
        else if message.senderBotFlag {
            return .bot
        }
        else {
            if case .photo = message.content {
                return .neutral
            }
            else {
                return .client
            }
        }
    }
    
    private func obtainStatusColor() -> UIColor {
        return JVDesign.colors.resolve(usage: .secondaryForeground)
    }
    
    private func obtainStatusFont() -> UIFont {
        return JVDesign.fonts.resolve(.italics(10), scaling: .caption1)
    }
    
    private func obtainMediumSystemFont() -> UIFont {
        return JVDesign.fonts.resolve(.regular(16), scaling: .callout)
    }
    
    private func obtainSmallSystemFont() -> UIFont {
        return JVDesign.fonts.resolve(.regular(12), scaling: .caption1)
    }
    
    private func obtainTimepointFont() -> UIFont {
        return JVDesign.fonts.resolve(.regular(12), scaling: .caption1)
    }
    
    private func obtainSenderFont() -> UIFont {
        return JVDesign.fonts.resolve(.regular(12), scaling: .caption1)
    }
    
    private func obtainTimeFont() -> UIFont {
        return JVDesign.fonts.resolve(.regular(12), scaling: .caption1)
    }
    
    private func obtainOrderDetailsFont() -> UIFont {
        return JVDesign.fonts.resolve(.regular(14), scaling: .body)
    }
    
    private func obtainOrderButtonFont() -> UIFont {
        return JVDesign.fonts.resolve(.semibold(16), scaling: .body)
    }
    
    private func obtainItemStyleForClient(contentStyle: JMTimelineStyle, backgroundType: ChatTimelineBackgroundType?) -> JMTimelineStyle {
        let backgroundColor: UIColor? = backgroundType.map { value in
            switch value {
            case .regular, .comment: return JVDesign.colors.resolve(usage: .clientBackground)
            case .specialDark: return JVDesign.colors.resolve(usage: .agentBackground)
            case .specialLight: return JVDesign.colors.resolve(usage: .primaryBackground)
            case .failed: return JVDesign.colors.resolve(usage: .clientBackground)
            }
        }
        
        return JMTimelineCompositeStyle(
            senderBackground: .clear,
            senderColor: JVDesign.colors.resolve(usage: .secondaryForeground),
            senderFont: obtainSenderFont(),
            senderPadding: .zero,
            senderCorner: 0,
            borderColor: nil,
            borderWidth: 0,
            backgroundColor: backgroundColor,
            foregroundColor: JVDesign.colors.resolve(usage: .oppositeForeground),
            statusColor: obtainStatusColor(),
            statusFont: obtainStatusFont(),
            timeRegularForegroundColor: (
                (backgroundType == .failed)
                ? JVDesign.colors.resolve(usage: .warningForeground)
                : JVDesign.colors.resolve(usage: .clientTime).jv_withAlpha(0.6)
            ),
            timeOverlayBackgroundColor: JVDesign.colors.resolve(usage: .oppositeBackground).jv_withAlpha(0.25),
            timeOverlayForegroundColor: (
                (backgroundType == .failed)
                ? JVDesign.colors.resolve(usage: .warningForeground)
                : JVDesign.colors.resolve(usage: .oppositeForeground).jv_withAlpha(0.85)
            ),
            timeFont: obtainTimeFont(),
            deliveryViewTintColor: JVDesign.colors.resolve(usage: .clientCheckmark).withAlphaComponent(0.6),
            reactionStyle: obtainReactionStyle(),
            contentStyle: contentStyle
        )
    }
    
    private func obtainItemStyleForAgent(contentStyle: JMTimelineStyle, backgroundType: ChatTimelineBackgroundType?) -> JMTimelineStyle {
        return JMTimelineCompositeStyle(
            senderBackground: .clear,
            senderColor: JVDesign.colors.resolve(usage: .secondaryForeground),
            senderFont: obtainSenderFont(),
            senderPadding: .zero,
            senderCorner: 0,
            borderColor: nil,
            borderWidth: 0,
            backgroundColor: backgroundType.map { type in
                switch type {
                case .regular: return JVDesign.colors.resolve(usage: .agentBackground)
                case .comment: return JVDesign.colors.resolve(usage: .commentBackground)
                case .specialDark: return JVDesign.colors.resolve(usage: .agentBackground)
                case .specialLight: return JVDesign.colors.resolve(usage: .primaryBackground)
                case .failed: return JVDesign.colors.resolve(usage: .agentBackground)
                }
            },
            foregroundColor: JVDesign.colors.resolve(usage: .primaryForeground),
            statusColor: obtainStatusColor(),
            statusFont: obtainStatusFont(),
            timeRegularForegroundColor: (
                (backgroundType == .failed)
                ? JVDesign.colors.resolve(usage: .warningForeground)
                : JVDesign.colors.resolve(usage: .agentTime)
            ),
            timeOverlayBackgroundColor: JVDesign.colors.resolve(usage: .oppositeBackground).jv_withAlpha(0.25),
            timeOverlayForegroundColor: (
                (backgroundType == .failed)
                ? JVDesign.colors.resolve(usage: .warningForeground)
                : JVDesign.colors.resolve(usage: .oppositeForeground).jv_withAlpha(0.85)
            ),
            timeFont: obtainTimeFont(),
            deliveryViewTintColor: JVDesign.colors.resolve(alias: .greenJivo),
            reactionStyle: obtainReactionStyle(),
            contentStyle: contentStyle
        )
    }
    
    private func obtainItemStyleForCall(contentStyle: JMTimelineStyle, backgroundType: ChatTimelineBackgroundType?) -> JMTimelineStyle {
        return JMTimelineCompositeStyle(
            senderBackground: .clear,
            senderColor: JVDesign.colors.resolve(usage: .secondaryForeground),
            senderFont: obtainSenderFont(),
            senderPadding: .zero,
            senderCorner: 0,
            borderColor: JVDesign.colors.resolve(usage: .callBorder),
            borderWidth: 1,
            backgroundColor: JVDesign.colors.resolve(usage: .primaryBackground),
            foregroundColor: JVDesign.colors.resolve(usage: .primaryForeground),
            statusColor: obtainStatusColor(),
            statusFont: obtainStatusFont(),
            timeRegularForegroundColor: JVDesign.colors.resolve(usage: .secondaryForeground),
            timeOverlayBackgroundColor: JVDesign.colors.resolve(usage: .oppositeBackground).jv_withAlpha(0.25),
            timeOverlayForegroundColor: JVDesign.colors.resolve(usage: .oppositeForeground).jv_withAlpha(0.85),
            timeFont: obtainTimeFont(),
            deliveryViewTintColor: JVDesign.colors.resolve(alias: .greenJivo),
            reactionStyle: obtainReactionStyle(),
            contentStyle: contentStyle
        )
    }
    
    private func obtainItemStyleForBot(contentStyle: JMTimelineStyle, backgroundType: ChatTimelineBackgroundType?) -> JMTimelineStyle {
        return JMTimelineCompositeStyle(
            senderBackground: JVDesign.colors.resolve(usage: .badgeBackground),
            senderColor: JVDesign.colors.resolve(usage: .oppositeForeground),
            senderFont: obtainSenderFont(),
            senderPadding: UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4),
            senderCorner: 4,
            borderColor: nil,
            borderWidth: 0,
            backgroundColor: backgroundType.map { type in
                switch type {
                case .regular: return JVDesign.colors.resolve(usage: .agentBackground)
                case .comment: return JVDesign.colors.resolve(usage: .commentBackground)
                case .specialDark: return JVDesign.colors.resolve(usage: .agentBackground)
                case .specialLight: return JVDesign.colors.resolve(usage: .primaryBackground)
                case .failed: return JVDesign.colors.resolve(usage: .agentBackground)
                }
            },
            foregroundColor: JVDesign.colors.resolve(usage: .primaryForeground),
            statusColor: obtainStatusColor(),
            statusFont: obtainStatusFont(),
            timeRegularForegroundColor: JVDesign.colors.resolve(usage: .agentTime),
            timeOverlayBackgroundColor: JVDesign.colors.resolve(usage: .oppositeBackground).jv_withAlpha(0.25),
            timeOverlayForegroundColor: JVDesign.colors.resolve(usage: .oppositeForeground).jv_withAlpha(0.85),
            timeFont: obtainTimeFont(),
            deliveryViewTintColor: JVDesign.colors.resolve(alias: .greenJivo),
            reactionStyle: obtainReactionStyle(),
            contentStyle: contentStyle
        )
    }
    
    private func obtainReactionStyle() -> JMTimelineReactionStyle {
        return JMTimelineReactionStyle(
            height: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.075,
            baseFont: JVDesign.fonts.resolve(.regular(30), scaling: .caption1),
            regularBackgroundColor: JVDesign.colors.resolve(usage: .agentBackground),
            regularNumberColor: JVDesign.colors.resolve(usage: .secondaryForeground),
            selectedBackgroundColor: JVDesign.colors.resolve(usage: .highlightBackground),
            selectedNumberColor: JVDesign.colors.resolve(usage: .highlightForeground),
            sidePaddingCoef: 0.3,
            emojiElement: .init(paddingCoef: 0.1, fontReducer: 4, pullingCoef: 0.01),
            counterElement: .init(paddingCoef: 0.2, fontReducer: 2, pullingCoef: -0.01),
            actionElement: .init(paddingCoef: 0.2, fontReducer: 0, pullingCoef: 0)
        )
    }
    
    //    private func detectBackgroundColor(message: Message) -> UIColor {
    //        switch detectSenderType(for: message) {
    //        case .client:
    //            return JVDesign.colors.resolve(usage: .clientBackground)
    //        case .agent:
    //            return JVDesign.colors.resolve(usage: .agentBackground)
    //        case .bot:
    //            return JVDesign.colors.resolve(usage: .primaryBackground)
    //        case .action:
    //            return JVDesign.colors.resolve(usage: .primaryBackground)
    //        }
    //    }
    //
    //    private func detectTimeColor(message: Message) -> UIColor {
    //        switch detectSenderType(for: message) {
    //        case .client where message.delivery.isFailure:
    //            return JVDesign.colors.resolve(usage: .warningForeground)
    //        case .client:
    //            return JVDesign.colors.resolve(usage: .clientTime).withAlpha(0.6)
    //        case .agent where message.delivery.isFailure:
    //            return JVDesign.colors.resolve(usage: .warningForeground)
    //        case .agent:
    //            return JVDesign.colors.resolve(usage: .agentTime)
    //        case .bot:
    //            return JVDesign.colors.resolve(usage: .agentTime)
    //        case .action:
    //            return JVDesign.colors.resolve(usage: .secondaryForeground)
    //        }
    //    }
    
    private func obtainPhotoErrorStubStyle() -> JMTimelinePhotoStyle.ErrorStubStyle {
        return JMTimelinePhotoStyle.ErrorStubStyle(
            backgroundColor: JVDesign.colors.resolve(usage: .photoLoadingErrorStubBackground),
            errorDescriptionColor: JVDesign.colors.resolve(usage: .photoLoadingErrorDescription)
        )
    }
    
    private func generateMessageLayoutValues() -> JMTimelineItemLayoutValues {
        return JMTimelineItemLayoutValues(
            margins: UIEdgeInsets(top: 13, left: 10, bottom: 10, right: 10),
            groupingCoef: 0.5
        )
    }
    
    private func generateSystemLayoutValues() -> JMTimelineItemLayoutValues {
        return JMTimelineItemLayoutValues(
            margins: UIEdgeInsets(top: 15, left: 0, bottom: 15, right: 0),
            groupingCoef: 0
        )
    }
    
    private func generateMessageMeta(message: JVMessage) -> JMTimelineMessageMeta {
        return JMTimelineMessageMeta(
            timepoint: provider.formattedDateForMessageEvent(message.date),
            delivery: obtainItemDelivery(for: message),
            status: message.systemStatus ?? String()
        )
    }
}

fileprivate extension TimeInterval {
    func ifPositive() -> TimeInterval? {
        return (self > 0 ? self : nil)
    }
}

fileprivate extension JVMessage {
    var systemStatus: String? {
        if isDeleted {
            return nil
        }
        else if let _ = updatedMeta {
            return loc["Message.Edited"]
        }
        else {
            return nil
        }
    }
}

extension UIColor {
    func darkenBy(value: CGFloat) -> UIColor {
        var scanr = CGFloat.zero, scang = CGFloat.zero, scanb = CGFloat.zero
        getRed(&scanr, green: &scang, blue: &scanb, alpha: nil)
        
        let r = max(0, scanr - value)
        let g = max(0, scang - value)
        let b = max(0, scanb - value)
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}

fileprivate extension JMTimelineLogicOptions {
    static func build(countable: Bool, cachable: Bool) -> JMTimelineLogicOptions {
        return JMTimelineLogicOptions()
            .union(countable ? [] : .isVirtual)
            .union(cachable ? .enableSizeCaching : [])
    }
}

//fileprivate func genstyle(font: UIFont?, lineHeight: CGFloat?) -> JMTimelineCompositePlainStyle {
//    return JMTimelineCompositePlainStyle(
//        textColor: .black,
//        identityColor: .green,
//        linkColor: .blue,
//        font: font ?? .systemFont(ofSize: 20),
//        boldFont: nil,
//        italicsFont: nil,
//        strikeFont: nil,
//        lineHeight: lineHeight ?? 20,
//        alignment: .left,
//        underlineStyle: nil,
//        parseMarkdown: true
//    )
//}

fileprivate func obtainSystemSmallFont() -> UIFont {
    return JVDesign.fonts.resolve(.regular(12), scaling: .caption1)
}

fileprivate func obtainSystemMediumFont() -> UIFont {
    return JVDesign.fonts.resolve(.regular(16), scaling: .callout)
}

fileprivate func obtainTooltipFont() -> UIFont {
    return JVDesign.fonts.resolve(.regular(12), scaling: .subheadline)
}

fileprivate func obtainCommentFont(isDeleted: Bool) -> UIFont {
    let weight: JVDesignFontWeight = isDeleted ? .italics : .regular
    let meta = JVDesignFontMeta(weight: weight, sizing: 16)
    return JVDesign.fonts.resolve(meta, scaling: .callout)
}

fileprivate func obtainEmojiFont() -> UIFont {
    return JVDesign.fonts.resolve(.regular(50), scaling: .title1)
}

fileprivate extension JVMessageDelivery {
    var isFailure: Bool {
        switch self {
        case .failed: return true
        default: return false
        }
    }
}
