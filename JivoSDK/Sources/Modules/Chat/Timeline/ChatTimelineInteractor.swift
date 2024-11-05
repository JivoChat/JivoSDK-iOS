//
//  ChatTimelineInteractor.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 29/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

import JMTimelineKit
import JMMarkdownKit

final class ChatTimelineInteractor: UIResponder, JVChatTimelineInteractor {
    func resolveCurrentChat() { }
    
    weak var timelineView: UIView?
    var requestMediaHandler: ((URL, String?) -> Void)?
    var tapHandler: ((String, ChatTimelineTap) -> Void)?
    var mediaBecameUnavailableHandler: ((URL, String?) -> Void)?
    
    private let clientManager: ISdkClientManager
    private let chatManager: ISdkChatManager
    private let remoteStorageService: IRemoteStorageService
    private let popupPresenterBridge: IPopupPresenterBridge
    private let databaseDriver: JVIDatabaseDriver
    private let preferencesDriver: IPreferencesDriver
    private let endpointAccessorProvider: () -> IKeychainAccessor
    
    private var interactedItemUUID: String?
    
    init(
        clientManager: ISdkClientManager,
        chatManager: ISdkChatManager,
        remoteStorageService: IRemoteStorageService,
        popupPresenterBridge: IPopupPresenterBridge,
        databaseDriver: JVIDatabaseDriver,
        preferencesDriver: IPreferencesDriver,
        endpointAccessorProvider: @escaping () -> IKeychainAccessor
    ) {
        self.clientManager = clientManager
        self.chatManager = chatManager
        self.remoteStorageService = remoteStorageService
        self.popupPresenterBridge = popupPresenterBridge
        self.databaseDriver = databaseDriver
        self.preferencesDriver = preferencesDriver
        self.endpointAccessorProvider = endpointAccessorProvider
    }
    
    func playCall(item: URL) {
    }

    func playMedia(item: URL) {
    }
    
    func pauseMedia(item: URL) {
    }
    
    func resumeMedia(item: URL) {
    }
    
    func seekMedia(item: URL, position: Float) {
    }
    
    func stopMedia(item: URL) {
    }
    
    func stopPlayingMedia(item: URL) {
    }
    
    func stopPlayingAllMedias() {
    }
    
    func toggleMessageReaction(uuid: String, emoji: String) {
    }
    
    func presentMessageReactions(uuid: String) {
    }
    
    func callForOrder(phone: String) {
    }
    
    func addPerson(name: String, phone: String) {
    }
    
    func call(phone: String) {
    }
    
    func requestMedia(url: URL, kind: RemoteStorageFileKind?, mime: String?, completion: @escaping (JMTimelineMediaStatus) -> Void) {
        let endpoint = endpointAccessorProvider().string
        remoteStorageService.retrieveMeta(endpoint: endpoint, originURL: url, caching: .enabled, on: .main) { [weak self] result in
            switch result {
            case .success:
                self?.remoteStorageService.retrieveMeta(endpoint: endpoint, originURL: url, caching: .disabled, on: .main) { result in
                    switch result {
                    case .success: break
                    case let .failure(error):
                        switch error {
                        case .notFromCloudStorage:
                            self?.requestMediaHandler?(url, mime)
                            
                        case .unauthorized:
                            completion(.accessDenied(loc["JV_FileAttachment_LinkStatus_Expired", "file_download_expired"]))
                            self?.mediaBecameUnavailableHandler?(url, mime)
                            
                        default:
                            completion(.unknownError(loc["JV_FileAttachment_LinkStatus_Unavailable", "file_download_unavailable"]))
                            self?.mediaBecameUnavailableHandler?(url, mime)
                        }
                    }
                }
                self?.requestMediaHandler?(url, mime)
                
            case let .failure(error):
                switch error {
                case .notFromCloudStorage:
                    self?.requestMediaHandler?(url, mime)
                    
                case .unauthorized:
                    completion(.accessDenied(loc["JV_FileAttachment_LinkStatus_Expired", "file_download_expired"]))
                    
                default:
                    completion(.unknownError(loc["JV_FileAttachment_LinkStatus_Unavailable", "file_download_unavailable"]))
                }
            }
        }
    }

    func joinConference(url: URL) {
    }
    
    func requestLocation(coordinate: CLLocationCoordinate2D) {
    }
    
    func performMessageSubaction(uuid: String, actionID: String) {
    }
    
    func sendMessage(text: String) {
        try? chatManager.sendMessage(
            trigger: .ui,
            text: text,
            attachments: .jv_empty)
    }
    
    func hasTouchingView() -> Bool {
        return false
    }
    
    func registerTouchingView(view: UIView) {
    }
    
    func unregisterTouchingView(view: UIView) {
    }
    
    func mediaPlayingStatus(item: URL) -> JMTimelineMediaPlayerItemStatus {
        return .failed
    }

    func follow(url: URL, interaction: JMMarkdownURLInteraction) {
        guard interaction == .shortTap else {
            return
        }
        
        switch url.host {
        case "mention":
            break
        default:
            UIApplication.shared.open(url)
        }
    }

    func senderIconTap(item: JMTimelineItem) {
    }
    
    func senderIconLongPress(item: JMTimelineItem) {
    }
    
    func systemButtonTap(buttonID: String) {
    }
    
    func toggleRateFormChange(item: JMTimelineItem, choice: Int, comment: String) {
        guard let message = databaseDriver.message(for: item.uid), jv_not(message.wasDeleted) else {
            return
        }
        
        chatManager.toggleRateForm(message: message, action: .change(choice: choice, comment: comment))
    }
    
    func toggleRateFormSubmit(item: JMTimelineItem, scale: ChatTimelineRateScale, choice: Int, comment: String) {
        guard let message = databaseDriver.message(for: item.uid), jv_not(message.wasDeleted) else {
            return
        }
        
        chatManager.toggleRateForm(
            message: message,
            action: .submit(
                scale: scale,
                choice: choice,
                comment: comment
            )
        )
    }
    
    func toggleRateFormClose(item: JMTimelineItem) {
        guard let message = databaseDriver.message(for: item.uid), jv_not(message.wasDeleted) else {
            return
        }
        
        chatManager.toggleRateForm(message: message, action: .dismiss)
    }
    
    func toggleContactForm(item: JMTimelineItem) {
        guard let message = databaseDriver.message(for: item.uid), jv_not(message.wasDeleted) else {
            return
        }
        
        chatManager.toggleContactForm(message: message)
    }
    
    func submitContactForm(values: TimelineContactFormControl.Values) {
        let info = JVSessionContactInfo(
            name: values.name?.jv_valuable,
            email: values.email?.jv_valuable,
            phone: values.phone?.jv_valuable,
            brief: nil
        )
        
        clientManager.setContactInfo(
            info: info,
            allowance: .allFields)
    }
    
    func constructMenuForMessage(uuid: String, container: UIView) {
//        tapHandler?(uuid, .long)
        
        interactedItemUUID = uuid
        
        guard timelineView?.canBecomeFirstResponder == true,
              UUID().uuidString.count == uuid.count
        else {
            return
        }
        
        popupPresenterBridge.displayMenu(
            within: .auto,
            anchor: container,
            title: nil,
            message: nil,
            items: [
                !canPerformCopy() ? .omit : .action(loc["JV_ChatTimeline_MessageAction_Copy", "options_copy"], .icon(.copy), .regular { [weak self] _ in
                    self?.performCopy()
                }),
                !canPerformResend() ? .omit : .action(loc["JV_ChatTimeline_MessageAction_Resend", "options_resend"], .icon(.again), .regular { [weak self] _ in
                    self?.performResend()
                }),
                !canPerformDelete() ? .omit : .action(loc["JV_ChatTimeline_MessageAction_Delete", "options_delete"], .icon(.delete), .regular { [weak self] _ in
                    self?.performDelete()
                }),
                .dismiss(.cancel)
            ])
    }
    
    func systemMessageTap(messageID: String?) {
    }
    
    func prepareForItem(uuid: String) {
    }
    
    func requestAudio(url: URL, mime: String?) {
        requestMediaHandler?(url, mime)
    }
    
    func requestWaveformPoints(for url: URL) {
        guard let resultedURL = URL(string: (url.absoluteString + "?width=512&thumb")) else { return }
        
        remoteStorageService.retrieveFile(
            endpoint: endpointAccessorProvider().string,
            originURL: resultedURL,
            quality: .original,
            caching: .disabled,
            on: .main) { res in
                print(res)
            }
    }
    
    func focusMessage(uid: String) {
    }
    
    func requestHistoryPast(item: JMTimelineItem) {
        guard let message = databaseDriver.message(for: item.uid) else { return }
        
        chatManager.requestMessageHistory(
            before: message.ID,
            behavior: .anyway)
    }
    
    func requestHistoryFuture(item: JMTimelineItem) {
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
    
    private func messageToCopy() -> MessageEntity? {
        guard let uuid = interactedItemUUID else { return nil }
        guard let message = databaseDriver.message(for: uuid), !(message.isDeleted) else { return nil }
        guard let _ = message.obtainObjectToCopy() else { return nil }
        return message
    }
    
    private func messageToResend() -> MessageEntity? {
        guard let uuid = interactedItemUUID else { return nil }
        guard let message = databaseDriver.message(for: uuid), !(message.isDeleted) else { return nil }
        guard case .failed = message.delivery else { return nil }
        return message
    }
    
    private func messageToDelete() -> MessageEntity? {
        guard let uuid = interactedItemUUID else { return nil }
        guard let message = databaseDriver.message(for: uuid), !(message.isDeleted) else { return nil }
        guard case .failed = message.delivery else { return nil }
        return message
    }
    
    @objc func canPerformCopy() -> Bool {
        guard let _ = messageToCopy() else { return false }
        return true
    }
    
    @objc func performCopy() {
        guard let message = messageToCopy() else { return }
        chatManager.copy(message: message)
    }
    
    @objc func canPerformResend() -> Bool {
        guard let _ = messageToResend() else { return false }
        return true
    }
    
    @objc func performResend() {
        guard let message = messageToResend() else { return }
        chatManager.resendMessage(uuid: message.UUID)
    }
    
    @objc func canPerformDelete() -> Bool {
        guard let _ = messageToDelete() else { return false }
        return true
    }
    
    @objc func performDelete() {
        guard let message = messageToDelete() else { return }
        chatManager.deleteMessage(uuid: message.UUID)
    }
}
