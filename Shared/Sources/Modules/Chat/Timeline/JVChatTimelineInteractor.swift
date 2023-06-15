//
//  ChatTimelineProvider.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 29/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import JMTimelineKit
import JMMarkdownKit
import Gzip
import JMCodingKit
import CoreLocation

protocol JVChatTimelineInteractor: JMTimelineInteractor {
    func playCall(item: URL)
    func playMedia(item: URL)
    func pauseMedia(item: URL)
    func resumeMedia(item: URL)
    func seekMedia(item: URL, position: Float)
    func stopMedia(item: URL)
    func stopPlayingMedia(item: URL)
    func stopPlayingAllMedias()
    
    func toggleMessageReaction(uuid: String, emoji: String)
    func presentMessageReactions(uuid: String)
    
    func callForOrder(phone: String)
    func addPerson(name: String, phone: String)
    func call(phone: String)
    func requestMedia(url: URL, kind: RemoteStorageFileKind?, mime: String?, completion: @escaping (JMTimelineMediaStatus) -> Void)
    func joinConference(url: URL)
    func requestLocation(coordinate: CLLocationCoordinate2D)
    func performMessageSubaction(uuid: String, actionID: String)
    func sendMessage(text: String)

    func registerTouchingView(view: UIView)
    func unregisterTouchingView(view: UIView)
    
    func mediaPlayingStatus(item: URL) -> JMTimelineMediaPlayerItemStatus
    func follow(url: URL, interaction: JMMarkdownURLInteraction)

    func senderIconTap(item: JMTimelineItem)
    func senderIconLongPress(item: JMTimelineItem)
    func systemButtonTap(buttonID: String)
    
    func toggleContactForm(item: JMTimelineItem)
    func submitContactForm(values: TimelineContactFormControl.Values)

    func constructMenuForMessage(uuid: String, container: UIView)
    
    func requestWaveformPoints(for url: URL)
}
