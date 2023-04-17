//  
//  ChatModulePresenter.swift
//  Pods
//
//  Created by Stan Potemkin on 11.08.2022.
//

import Foundation
import UIKit

enum ChatModulePresenterUpdate {
    enum PrimaryLayout {
        case loading
        case chatting
        case unavailable
    }
    
    case primaryLayout(PrimaryLayout)
    case headerIcon(UIImage)
    case headerTitle(String)
    case headerSubtitle(String)
    case inputUpdate(ChatModuleInputUpdate)
    case timelineScrollToBottom
    case timelineRecreate
    case discardAllAttachments
}

final class ChatModulePresenter
: RTEModulePresenter<
    ChatModulePipeline,
    ChatModulePresenterUpdate,
    ChatModuleViewIntent,
    ChatModuleCoreEvent,
    ChatModuleJointInput,
    ChatModuleState
> {
    override func update(firstAppear: Bool) {
        if firstAppear {
            feedPrimaryLayout()
            pipeline?.notify(update: .inputUpdate(.update(.initial)))
        }
    }
    
    override func handleCore(event: ChatModuleCoreEvent) {
        switch event {
        case .hasUpdates:
            break
        case .authorizationStateUpdated:
            feedPrimaryLayout()
        case .inputUpdate(let updates):
            pipeline?.notify(update: .inputUpdate(updates))
        case .agentsUpdate:
            feedTitleBarContent()
        case .hasInputUpdates:
//            feedReplyControlState()
            break
        case .messageSent:
            pipeline?.notify(update: .discardAllAttachments)
        default:
            break
        }
    }
    
    override func handleView(intent: ChatModuleViewIntent) {
    }
    
    override func handleJoint(input: ChatModuleJointInput) {
        switch input {
        case .documentsLimitExceeded:
            pipeline?.notify(update: .inputUpdate(.shakeAttachments))
        default:
            break
        }
    }
    
    private func feedPrimaryLayout() {
        switch state.authorizationState {
        case .unknown:
            pipeline?.notify(update: .primaryLayout(.loading))
        case .ready:
            pipeline?.notify(update: .primaryLayout(.chatting))
        case .unavailable:
            pipeline?.notify(update: .primaryLayout(.unavailable))
        }
    }
    
    private func feedTitleBarContent() {
        func _updateLoadableIcon(link: String, defaultIcon: UIImage) {
            guard let url = URL(string: link)
            else {
                pipeline?.notify(update: .headerIcon(defaultIcon))
                return
            }
            
            URLSession.shared.dataTask(with: URLRequest(url: url)) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    let avatar = data.flatMap(UIImage.init(data:))
                    self?.pipeline?.notify(update: .headerIcon(avatar ?? defaultIcon))
                }
            }.resume()
        }
        
        if state.activeAgents.isEmpty {
            pipeline?.notify(update: .headerIcon(state.uiConfig.icon))
            pipeline?.notify(update: .headerTitle(state.uiConfig.titleCaption))
            pipeline?.notify(update: .headerSubtitle(state.uiConfig.subtitleCaption))
        }
        else if state.activeAgents.count > 1 {
            let title: String = state.activeAgents
                .compactMap {
                    $0.name
                        .split(separator: " ")
                        .first
                        .flatMap(String.init)
                }
                .joined(separator: ", ")
            
            pipeline?.notify(update: .headerIcon(UIImage()))
            pipeline?.notify(update: .headerTitle(title))
        }
        else if let agent = state.activeAgents.first {
            pipeline?.notify(update: .headerTitle(agent.name))
            
            if agent.id >= 0 {
                _updateLoadableIcon(link: agent.avatarLink, defaultIcon: state.uiConfig.icon)
            }
            else {
                let defaultIcon = UIImage(named: "avatar_bot", in: .jv_shared, compatibleWith: nil) ?? UIImage()
                _updateLoadableIcon(link: agent.avatarLink, defaultIcon: defaultIcon)
            }
        }
    }
    
//    private func feedReplyControlState() {
//        pipeline?.notify(
//            update: .inputUpdate(.update(.init(
//                input: (
//                    state.shouldEnableInput
//                    ? .enabled(placeholder: loc["input_message_placeholder"], text: state.inputText)
//                    : .disabled(reason: state.placeholderForInput)
//                ),
//                submit: state.submitState,
//                menu: .active
//            )))
//        )
//    }
}
