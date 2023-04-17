//
//  SystemMessagingService.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 22/11/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
#if canImport(JivoFoundation)
import JivoFoundation
#endif

import JMTimelineKit

protocol ISystemMessagingService: AnyObject {
    func register(context: JVIDatabaseContext, change: JVMessageGeneralSystemChange, meta: LocalizedMeta, discardable: Bool) -> JVMessage
    func discard(context: JVIDatabaseContext, clientID: Int)
    func generateChatCancelled() -> LocalizedMeta
    func generateChatAccepted() -> LocalizedMeta
    func generateChatHasGone() -> LocalizedMeta
    func generateChatAlreadyTaken(agent: JVAgent) -> LocalizedMeta
    func generateChatHasBeenArchived() -> LocalizedMeta
    func generateChatCouldNotLoad() -> LocalizedMeta
    func generateTransferringRequest(to agent: JVAgent, comment: String?) -> LocalizedMeta
    func generateTransferringComplete(to agent: JVAgent, comment: String?) -> LocalizedMeta
    func generateTransferringRequest(to department: JVDepartment, comment: String?) -> LocalizedMeta
    func generateTransferringComplete(to department: JVDepartment, comment: String?) -> LocalizedMeta
    func generateTransferringMeta(inviter: JVAgent, comment: String?) -> LocalizedMeta
    func generateTransferMeta(inviter: JVAgent, assistant: JVAgent, comment: String?) -> LocalizedMeta
    func generateTransferMeta(inviter: JVAgent, department: JVDepartment, assistant: JVAgent, comment: String?) -> LocalizedMeta
    func generateTransferCancelMeta(inviter: JVAgent) -> LocalizedMeta
    func generateInvitingRequest(to agent: JVAgent, comment: String?) -> LocalizedMeta
    func generateInvitingComplete(to agent: JVAgent, comment: String?) -> LocalizedMeta
    func generateInvitingMeta(inviter: JVAgent, comment: String?) -> LocalizedMeta
    func generateInviteMeta(inviter: JVAgent?, assistant: JVAgent, comment: String?) -> LocalizedMeta
    func generateInviteCancelMeta(inviter: JVAgent) -> LocalizedMeta
    func generateGroupJoinMeta(inviter: JVAgent?, assistant: JVAgent, comment: String?) -> LocalizedMeta
    func generateStartMeta() -> LocalizedMeta
    func generateAgentLeftFromClient(agent: JVAgent) -> LocalizedMeta
    func generateAgentLeftFromGroup(agent: JVAgent, kicker: JVAgent?) -> LocalizedMeta
    func generatePageMeta(previousPage: JVPage?, currentPage: JVPageGeneralChange?) -> LocalizedMeta?
    func generateMediaUploading(comment: String?) -> LocalizedMeta
    func generateClientWithEmailLeft() -> LocalizedMeta
    func generateClientWithoutEmailLeft() -> LocalizedMeta
    func generateCloseBecauseFinished(date: Date) -> LocalizedMeta
    func generateCloseBecauseAlreadyTaken(date: Date) -> LocalizedMeta
    func generateMentionNotPresented(agents: [JVAgent]) -> LocalizedMeta
    func generateCallPreview(call: JVMessageBodyCall) -> String
    func generateTaskPreview(task: JVMessageBodyTask, by creatorAgent: JVAgent, status: JVMessageBodyTaskStatus) -> String
    func generatePreviewMeta(isGroup: Bool, message: JVMessage) -> LocalizedMeta
    func generatePreviewPlain(isGroup: Bool, message: JVMessage) -> String
    func generateTransferringMeta(chat: JVChat) -> LocalizedMeta?
}

final class SystemMessagingService: ISystemMessagingService {
    fileprivate struct Item {
        let change: JVMessageGeneralSystemChange
        let meta: LocalizedMeta
        let discardable: Bool
        var messageUUID: String!
    }
    
    private let thread: JivoFoundation.JVIDispatchThread
    private let databaseDriver: JVIDatabaseDriver
    private let formattingProvider: IFormattingProvider
    
    private var items = [Item]()
    private var localizedMetas = [String: LocalizedMeta]()
    
    init(thread: JivoFoundation.JVIDispatchThread, databaseDriver: JVIDatabaseDriver, formattingProvider: IFormattingProvider) {
        self.thread = thread
        self.databaseDriver = databaseDriver
        self.formattingProvider = formattingProvider
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLocaleChanged),
            name: .jvLocaleDidChange,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func register(context: JVIDatabaseContext, change: JVMessageGeneralSystemChange, meta: LocalizedMeta, discardable: Bool) -> JVMessage {
        var item = SystemMessagingService.Item(change: change, meta: meta, discardable: discardable, messageUUID: nil)
        let message = process(context: context, item: &item)
        items.append(item)
        return message
    }

    func discard(context: JVIDatabaseContext, clientID: Int) {
        let uuids: [String] = items.compactMap { item in
            guard item.change.clientID == clientID else { return nil }
            guard item.discardable else { return nil }
            return item.messageUUID
        }

        _ = context.removeMessages(uuids: uuids)
    }

    func generateChatCancelled() -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.Invitation.CancelBySystem"),
            args: [],
            suffix: nil,
            interactiveID: nil
        )
    }
    
    func generateChatAccepted() -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.Transfer.AcceptedToYou"),
            args: [],
            suffix: nil,
            interactiveID: nil
        )
    }
    
    func generateChatHasGone() -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Me.Connection.ChatHasGone"),
            args: [],
            suffix: nil,
            interactiveID: nil
        )
    }
    
    func generateChatAlreadyTaken(agent: JVAgent) -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.Invitation.CancelByAgent"),
            args: [
                agent.displayName(kind: .decorative(.role))
            ],
            suffix: nil,
            interactiveID: nil
        )
    }

    func generateChatHasBeenArchived() -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.HasBeenArchived"),
            args: [],
            suffix: nil,
            interactiveID: nil
        )
    }
    
    func generateChatCouldNotLoad() -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.CouldNotLoad"),
            args: [],
            suffix: nil,
            interactiveID: nil
        )
    }

    func generateTransferringRequest(to agent: JVAgent, comment: String?) -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.Transfer.Requested_v2"),
            args: [
                agent.displayName(kind: .decorative(.role))
            ],
            suffix: wrapCommentIfNeeded(comment),
            interactiveID: nil
        )
    }
    
    func generateTransferringComplete(to agent: JVAgent, comment: String?) -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.Transfer.Completed"),
            args: [
                agent.displayName(kind: .decorative(.role))
            ],
            suffix: wrapCommentIfNeeded(comment),
            interactiveID: nil
        )
    }
    
    func generateTransferringRequest(to department: JVDepartment, comment: String?) -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.Transfer.Requested.Group_v2"),
            args: [
                department.displayName(kind: .decorative(.role))
            ],
            suffix: wrapCommentIfNeeded(comment),
            interactiveID: nil
        )
    }
    
    func generateTransferringComplete(to department: JVDepartment, comment: String?) -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.Transfer.Completed"),
            args: [
                department.displayName(kind: .decorative(.role))
            ],
            suffix: wrapCommentIfNeeded(comment),
            interactiveID: nil
        )
    }
    
    func generateTransferringMeta(inviter: JVAgent, comment: String?) -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.Transfer.AgentToYouRequest"),
            args: [
                inviter.displayName(kind: .decorative(.role))
            ],
            suffix: wrapCommentIfNeeded(comment),
            interactiveID: nil
        )
    }
    
    func generateTransferMeta(inviter: JVAgent, assistant: JVAgent, comment: String?) -> LocalizedMeta {
        if !inviter.isMe, !assistant.isMe {
            return LocalizedMeta(
                mode: .format("Chat.System.Transfer.AgentToAgent_v2"),
                args: [
                    inviter.displayName(kind: .decorative(.role)),
                    assistant.displayName(kind: .decorative(.role))
                ],
                suffix: wrapCommentIfNeeded(comment),
                interactiveID: nil
            )
        }
        else if !inviter.isMe {
            return LocalizedMeta(
                mode: .format("Chat.System.Transfer.AgentToYou"),
                args: [
                    inviter.displayName(kind: .decorative(.role))
                ],
                suffix: wrapCommentIfNeeded(comment),
                interactiveID: nil
            )
        }
        else /* if !assistant.isMe */ {
            return LocalizedMeta(
                mode: .format("Chat.System.Transfer.YouToAgent"),
                args: [
                    assistant.displayName(kind: .decorative(.role))
                ],
                suffix: wrapCommentIfNeeded(comment),
                interactiveID: nil
            )
        }
    }
    
    func generateTransferMeta(inviter: JVAgent, department: JVDepartment, assistant: JVAgent, comment: String?) -> LocalizedMeta {
        if !inviter.isMe, !assistant.isMe {
            return LocalizedMeta(
                mode: .format("Chat.System.Transfer.AgentToDepartment"),
                args: [
                    inviter.displayName(kind: .decorative(.role)),
                    assistant.displayName(kind: .decorative(.role)),
                    department.displayName(kind: .decorative(.role))
                ],
                suffix: wrapCommentIfNeeded(comment),
                interactiveID: nil
            )
        }
        else if !inviter.isMe {
            return LocalizedMeta(
                mode: .format("Chat.System.Transfer.DepartmentToYou"),
                args: [
                    inviter.displayName(kind: .decorative(.role)),
                    department.displayName(kind: .decorative(.role))
                ],
                suffix: wrapCommentIfNeeded(comment),
                interactiveID: nil
            )
        }
        else /* if !assistant.isMe */ {
            return LocalizedMeta(
                mode: .format("Chat.System.Transfer.YouToDepartment"),
                args: [
                    assistant.displayName(kind: .decorative(.role)),
                    department.displayName(kind: .decorative(.role))
                ],
                suffix: wrapCommentIfNeeded(comment),
                interactiveID: nil
            )
        }
    }
    
    func generateTransferCancelMeta(inviter: JVAgent) -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.Transfer.AgentToYouCancelled"),
            args: [
                inviter.displayName(kind: .decorative(.role))
            ],
            suffix: nil,
            interactiveID: nil
        )
    }
    
    func generateInvitingRequest(to agent: JVAgent, comment: String?) -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.Assist.Requested"),
            args: [
                agent.displayName(kind: .decorative(.role))
            ],
            suffix: wrapCommentIfNeeded(comment),
            interactiveID: nil
        )
    }
    
    func generateInvitingComplete(to agent: JVAgent, comment: String?) -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.Assist.Completed"),
            args: [
                agent.displayName(kind: .decorative(.role))
            ],
            suffix: wrapCommentIfNeeded(comment),
            interactiveID: nil
        )
    }
    
    func generateInvitingMeta(inviter: JVAgent, comment: String?) -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.Assist.AgentToYouRequest"),
            args: [
                inviter.displayName(kind: .decorative(.role))
            ],
            suffix: wrapCommentIfNeeded(comment),
            interactiveID: nil
        )
    }
    
    func generateInviteMeta(inviter: JVAgent?, assistant: JVAgent, comment: String?) -> LocalizedMeta {
        guard let inviter = inviter, inviter.ID != assistant.ID else {
            return LocalizedMeta(
                mode: .format("Chat.System.JoinedGroup"),
                args: [
                    assistant.displayName(kind: .decorative(.role))
                ],
                suffix: nil,
                interactiveID: nil
            )
        }
        
        if !inviter.isMe, !assistant.isMe {
            return LocalizedMeta(
                mode: .format("Chat.System.Assist.AgentToAgent"),
                args: [
                    assistant.displayName(kind: .decorative(.role)),
                    inviter.displayName(kind: .decorative(.role))
                ],
                suffix: wrapCommentIfNeeded(comment),
                interactiveID: nil
            )
        }
        else if !inviter.isMe {
            return LocalizedMeta(
                mode: .format("Chat.System.Assist.AgentToYou"),
                args: [
                    inviter.displayName(kind: .decorative(.role))
                ],
                suffix: wrapCommentIfNeeded(comment),
                interactiveID: nil
            )
        }
        else /* if !assistant.isMe */ {
            return LocalizedMeta(
                mode: .format("Chat.System.Assist.YouToAgent"),
                args: [
                    assistant.displayName(kind: .decorative(.role))
                ],
                suffix: wrapCommentIfNeeded(comment),
                interactiveID: nil
            )
        }
    }
    
    func generateInviteCancelMeta(inviter: JVAgent) -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.Assist.AgentToYouCancelled"),
            args: [
                inviter.displayName(kind: .decorative(.role))
            ],
            suffix: nil,
            interactiveID: nil
        )
    }
    
    func generateGroupJoinMeta(inviter: JVAgent?, assistant: JVAgent, comment: String?) -> LocalizedMeta {
        if let inviter = inviter, inviter.ID != assistant.ID {
            if inviter.ID == assistant.ID {
                return LocalizedMeta(
                    mode: .format("Chat.System.Group.JoinSelf"),
                    args: [
                        assistant.displayName(kind: .decorative(.role))
                    ],
                    suffix: nil,
                    interactiveID: nil
                )
            }
            else {
                return LocalizedMeta(
                    mode: .format("Chat.System.Group.JoinInvite"),
                    args: [
                        assistant.displayName(kind: .decorative(.role)),
                        inviter.displayName(kind: .decorative(.role))
                    ],
                    suffix: nil,
                    interactiveID: nil
                )
            }
        }
        else {
            return LocalizedMeta(
                mode: .format("Chat.System.Group.JoinAuto"),
                args: [
                    assistant.displayName(kind: .decorative(.role))
                ],
                suffix: nil,
                interactiveID: nil
            )
        }
    }
    
    func generateStartMeta() -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.Visitor.Invited"),
            args: [],
            suffix: nil,
            interactiveID: nil
        )
    }
    
    func generateAgentLeftFromClient(agent: JVAgent) -> LocalizedMeta {
        if agent.isMe {
            return LocalizedMeta(
                mode: .format("Chat.System.Assist.MeLeft"),
                args: [],
                suffix: nil,
                interactiveID: nil
            )
        }
        else {
            return LocalizedMeta(
                mode: .format("Chat.System.Assist.AgentLeft"),
                args: [
                    agent.displayName(kind: .decorative(.role))
                ],
                suffix: nil,
                interactiveID: nil
            )
        }
    }

    func generateAgentLeftFromGroup(agent: JVAgent, kicker: JVAgent?) -> LocalizedMeta {
        if let kicker = kicker {
            return LocalizedMeta(
                mode: .format("Chat.System.Group.LeaveKicked"),
                args: [
                    kicker.displayName(kind: .decorative(.role)),
                    agent.displayName(kind: .decorative(.role))
                ],
                suffix: nil,
                interactiveID: nil
            )
        }
        else {
            return LocalizedMeta(
                mode: .format("Chat.System.Group.LeaveSelf"),
                args: [
                    agent.displayName(kind: .decorative(.role))
                ],
                suffix: nil,
                interactiveID: nil
            )
        }
    }
    
    func generatePageMeta(previousPage: JVPage?, currentPage: JVPageGeneralChange?) -> LocalizedMeta? {
        guard let currentPage = currentPage else { return nil }
        
        let previousLink = previousPage?.URL?.absoluteString
        let currentLink = currentPage.URL

        guard let _ = previousLink else { return nil }
        guard currentLink != previousLink else { return nil }
        guard let currentURL = URL(string: currentLink) else { return nil }
        
        return LocalizedMeta(
            mode: .format("Chat.System.MovedToPage"),
            args: [
                currentPage.title
            ],
            suffix: nil,
            interactiveID: JMTimelineItemInteractiveID.navigatedToPage(url: currentURL)
        )
    }
    
    func generateMediaUploading(comment: String?) -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.Media.Uploading"),
            args: [],
            suffix: wrapCommentIfNeeded(comment, separated: false),
            interactiveID: nil
        )
    }

    func generateClientWithEmailLeft() -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.ClientLeft.Email"),
            args: [],
            suffix: nil,
            interactiveID: nil
        )
    }
    
    func generateClientWithoutEmailLeft() -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format("Chat.System.ClientLeft"),
            args: [],
            suffix: nil,
            interactiveID: nil
        )
    }
    
    func generateCloseBecauseFinished(date: Date) -> LocalizedMeta {
        let delay = formattingProvider.interval(
            between: Date(),
            and: date,
            style: .timeToTermination
        )
        
        return LocalizedMeta(
            mode: .format("Chat.System.Termination.ByClient"),
            args: [
                delay
            ],
            suffix: nil,
            interactiveID: nil
        )
    }
    
    func generateCloseBecauseAlreadyTaken(date: Date) -> LocalizedMeta {
        let delay = formattingProvider.interval(
            between: Date(),
            and: date,
            style: .timeToTermination
        )
        
        return LocalizedMeta(
            mode: .format("Chat.System.Termination.ByAgent"),
            args: [
                delay
            ],
            suffix: nil,
            interactiveID: nil
        )
    }

    func generateMentionNotPresented(agents: [JVAgent]) -> LocalizedMeta {
        return LocalizedMeta(
            mode: .format(
                agents.count > 1
                    ? "Chat.System.Mention.MultipleNotPresented"
                    : "Chat.System.Mention.SingleNotPresented"
            ),
            args: [
                agents
                    .map { $0.displayName(kind: .decorative(.role)) }
                    .joined(separator: ", ")
            ],
            suffix: nil,
            interactiveID: nil
        )
    }
    
    func generateCallPreview(call: JVMessageBodyCall) -> String {
        let type: String
        switch call.type {
        case .callback where call.isFailed: type = loc["Message.Call.Callback.Missed"]
        case .callback: type = loc["Message.Call.Type.Callback"]
        case .outgoing where call.isFailed: type = loc["Message.Call.Status.Failed"]
        case .outgoing: type = loc["Message.Call.Type.Outgoing"]
        case .incoming where call.isFailed: type = loc["Message.Call.Status.Missed"]
        case .incoming: type = loc["Message.Call.Type.Incoming"]
        case .unknown: type = loc["Message.Preview.Call"]
        @unknown default: type = loc["Message.Preview.Call"]
        }

        if let phone = call.phone {
            let number = formattingProvider.format(
                phone: phone,
                style: .printable,
                countryCode: nil,
                supportsFallback: false
            )

            return "\(type)\n\(number)"
        }
        else {
            return loc["Message.Call.ToWidget"]
        }
    }
    
    func generateTaskPreview(task: JVMessageBodyTask, by creatorAgent: JVAgent, status: JVMessageBodyTaskStatus) -> String {
        let formula: String
        switch status {
        case .created: formula = loc["Reminder.Created.Formula"]
        case .updated: formula = loc["Reminder.Updated.Formula"]
        case .completed: formula = loc["Reminder.Completed.Formula"]
        case .deleted: formula = loc["Reminder.Deleted.Formula"]
        case .fired: formula = loc["Reminder.Fired.Formula"]
        default: return String()
        }

        let creatorName = creatorAgent.isMe ? nil : creatorAgent.displayName(kind: .decorative(.role))
        let comment = task.text.jv_valuable
        let toYou = (creatorAgent.isMe != true && task.agent?.isMe == true)
        let toSelf = (task.agent?.ID == creatorAgent.ID)
        let targetName = (toYou || toSelf ? nil : task.agent?.displayName(kind: .decorative(.role)))
        let fireDate = formattingProvider.format(date: task.notifyAt, style: .taskFireDate)
        let fireTime = formattingProvider.format(date: task.notifyAt, style: .taskFireTime)

        let parser = JVPureParserTool()
        parser.assign(variable: "creatorName", value: creatorName)
        parser.assign(variable: "comment", value: comment)
        parser.assign(variable: "targetName", value: targetName)
        parser.activate(alias: "target", !toSelf)
        parser.assign(variable: "date", value: fireDate)
        parser.assign(variable: "time", value: fireTime)
        
        let result = parser.execute(formula, collapseSpaces: true)
        return result
    }
    
    func generatePreviewMeta(isGroup: Bool, message: JVMessage) -> LocalizedMeta {
        guard !(message.wasDeleted) else {
            return .init(exact: loc["Message.Deleted"])
        }
        
        switch message.content {
        case .proactive(let text):
            return .init(exact: text.jv_plain())
            
        case .offline(let text):
            return .init(exact: text.jv_plain())

        case .text(let text):
            return .init(exact: text.jv_plain())

        case .comment(let text):
            return .init(exact: text.jv_plain())

        case .email(_, _, _, let text):
            return .init(exact: text.jv_plain())

        case .transfer(let agentFrom, let agentTo):
            let meta = generateTransferMeta(
                inviter: agentFrom,
                assistant: agentTo,
                comment: message.text.jv_valuable)
            return .init(exact: meta.localized().jv_plain())
            
        case .transferDepartment(let agentFrom, let departmentTo, let agentTo):
            let meta = generateTransferMeta(
                inviter: agentFrom,
                department: departmentTo,
                assistant: agentTo,
                comment: message.text.jv_valuable)
            return .init(exact: meta.localized().jv_plain())

        case .join(let assistant, let byAgent) where isGroup:
            let meta = generateGroupJoinMeta(
                inviter: byAgent,
                assistant: assistant,
                comment: message.text.jv_valuable)
            return .init(exact: meta.localized().jv_plain())
            
        case .join(let assistant, let byAgent):
            let meta = generateInviteMeta(
                inviter: byAgent,
                assistant: assistant,
                comment: message.text.jv_valuable)
            return .init(exact: meta.localized().jv_plain())
            
        case .left(let agent, let kicker) where isGroup:
            let meta = generateAgentLeftFromGroup(
                agent: agent,
                kicker: kicker)
            return .init(exact: meta.localized().jv_plain())
            
        case .left(let agent, _):
            let meta = generateAgentLeftFromClient(
                agent: agent)
            return .init(exact: meta.localized().jv_plain())
            
        case .photo:
            let link = (message.media?.fullURL?.absoluteString ?? message.rawText).jv_plain()
            let parts = link.split(separator: " ")
            
            if link.contains("//media") {
                return .init(exact: "🖼 \(loc["Chat.Media.Image"])")
            }
            else if parts.count == 1, let url = URL(string: link) {
                return .init(exact: "🖼 \(url.lastPathComponent)")
            }
            else if parts.count == 2, let symbol = parts.first, let link = parts.last, let url = URL(string: String(link)) {
                return .init(exact: "\(symbol) \(url.lastPathComponent)")
            }
            else {
                return .init(exact: link)
            }
            
        case .file:
            let link = (message.media?.fullURL?.absoluteString ?? message.rawText).jv_plain()
            let parts = link.split(separator: " ")
            
            if message.media?.type == .voice {
                return .init(exact: "🗣 \(loc["Message.Voice.Title"])")
            } else if message.media?.type == .audio {
                return .init(exact: "🔊 \(loc["Message.Preview.Audio"])")
            } else if message.media?.type == .video {
                return .init(exact: "📷 \(loc["Message.Preview.Video"])")
            }
            else if link.contains("//media") {
                return .init(exact: "📄 \(loc["Chat.Media.Document"])")
            }
            else if parts.count == 1, let url = URL(string: link) {
                return .init(exact: "📄 \(url.lastPathComponent)")
            }
            else if parts.count == 2, let symbol = parts.first, let link = parts.last, let url = URL(string: String(link)) {
                return .init(exact: "\(symbol) \(url.lastPathComponent)")
            }
            else {
                return .init(exact: link)
            }
            
        case .call(let call):
            let value = generateCallPreview(call: call)
            return .init(exact: value)

        case .line:
            let value = loc["Message.Preview.Line"].jv_plain()
            return .init(exact: value)

        case .task(let task):
            guard let agent = message.senderAgent ?? task.agent else { return .init(exact: .jv_empty) }
            let value = generateTaskPreview(task: task, by: agent, status: message.taskStatus)
            return .init(exact: value)
            
        case .bot(let text, _, _):
            return .init(exact: text.jv_plain())
            
        case .order(_, _, let subject, _, _):
            return .init(exact: subject.jv_plain())
            
        case .conference:
            return .init(exact: loc["Conference.Description"].jv_plain())
            
        case .story(let story):
            return .init(exact: story.text)
            
        @unknown default:
            return .init(exact: .jv_empty)
        }
    }
    
    func generatePreviewPlain(isGroup: Bool, message: JVMessage) -> String {
        return generatePreviewMeta(isGroup: isGroup, message: message).localized()
    }
    
    func generateTransferringMeta(chat: JVChat) -> LocalizedMeta? {
        guard let attendee = chat.attendee else { return nil }
        
        if case let .invitedByAgent(agent, toAssist, comment) = attendee.relation {
            if chat.m_transfer_cancelled {
                if toAssist {
                    return generateInviteCancelMeta(inviter: agent)
                }
                else {
                    return generateTransferCancelMeta(inviter: agent)
                }
            }
            else {
                if toAssist {
                    return generateInvitingMeta(inviter: agent, comment: comment)
                }
                else {
                    return generateTransferringMeta(inviter: agent, comment: comment)
                }
            }
        }
        else {
            return nil
        }
    }

    private func wrapCommentIfNeeded(_ comment: String?, separated: Bool = true) -> String? {
        let separator = separated ? "\n" : String()
        return comment?.jv_valuable.map { return "\(separator)\n«\($0)»" }
    }
    
    private func process(context: JVIDatabaseContext, item: inout Item) -> JVMessage {
        let message = context.createMessage(with: item.change)
        item.messageUUID = message.UUID
        localizedMetas[message.UUID] = item.meta
        return message
    }
    
    private func performLocalizingUpdate() {
        databaseDriver.readwrite { context in
            let items = self.localizedMetas
            items.forEach { item in
                let change = JVMessageTextChange(
                    UUID: item.key,
                    text: item.value.localized()
                )
                
                if context.update(of: JVMessage.self, with: change) == nil {
                    self.localizedMetas.removeValue(forKey: item.key)
                }
            }
        }
    }
    
    @objc private func handleLocaleChanged() {
        thread.async { [unowned self] in
            performLocalizingUpdate()
        }
    }
}
