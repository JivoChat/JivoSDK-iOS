//
//  PreferencesDriver+Extension.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 24.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import JFEmojiPicker


extension PreferencesToken {
    static let initialLoginAttempt = PreferencesToken(key: "initialLoginAttempt", hint: Bool.self)
    static let lastDownAt = PreferencesToken(key: "lastDownAt", hint: Date.self)
    static let chatNewSound = PreferencesToken(key: "chatNewSound", hint: DevicePlaybackSound.self)
    static let chatMessageSound = PreferencesToken(key: "chatMessageSound", hint: DevicePlaybackSound.self)
    static let groupMessageSound = PreferencesToken(key: "groupMessageSound", hint: DevicePlaybackSound.self)
    static let chatLostSound = PreferencesToken(key: "chatLostSound", hint: DevicePlaybackSound.self)
    static let sessionBreakSound = PreferencesToken(key: "sessionBreakSound", hint: DevicePlaybackSound.self)
    static let worktimeSound = PreferencesToken(key: "worktimeSound", hint: DevicePlaybackSound.self)
    static let systemPushSoundEnabled = PreferencesToken(key: "systemPushSoundEnabled", hint: Bool.self)
    static let repeatUnreadNotificationsEnabled = PreferencesToken(key: "repeatUnreadNotificationsEnabled", hint: Bool.self)
    static let isOnline = PreferencesToken(key: "isOnline", hint: Bool.self)
    static let quickEmojis = PreferencesToken(key: "quickEmojis", hint: [String].self)
    static let quickAnswers = PreferencesToken(key: "quickAnswers", hint: [String].self)
    static let preferredCallerIndex = PreferencesToken(key: "preferredCallerIndex", hint: Int.self)
    static let preferredJournalLevel = PreferencesToken(key: "preferredJournalLevel", hint: JournalLevel.self)
    static let lastInformedFeature = PreferencesToken(key: "lastInformedFeature", hint: Int.self)
    static let preferredQuickPhraseTag = PreferencesToken(key: "preferredQuickPhraseTag", hint: String.self)
    static let quickLinks = PreferencesToken(key: "quickLinks", hint: [QuickLink].self)
    static let recentExceptionMeta = PreferencesToken(key: "recentExceptionMeta", hint: Data.self)
    static let recentInterfaceState = PreferencesToken(key: "recentInterfaceState", hint: Data.self)
}

struct QuickLink: Codable {
    let title: String
    let url: URL
}

extension IPreferencesDriver {
//    let quickAnswersObserver = JVBroadcastUniqueTool<[String]>()

    func registerDefaultValues() {
        register(
            defaults: [
                retrieveAccessor(forToken: .isOnline).key: true,
                retrieveAccessor(forToken: .vibroEnabled).key: true,
                
                // MOB-2601: populate the external Emoji struct
                // to get the startup favorite pickable Emoji items
                "com.levantAJ.EmojiPicker.frequentlyUsed": (try? JSONEncoder().encode([
                    Emoji(emojis: ["🙂"], selectedEmoji: nil),
                    Emoji(emojis: ["😁"], selectedEmoji: nil),
                    Emoji(emojis: ["🤔"], selectedEmoji: nil),
                    Emoji(emojis: ["👍", "👍🏻", "👍🏼", "👍🏽", "👍🏾", "👍🏿"], selectedEmoji: nil)
                ])) ?? Data()
            ]
        )
        
        let initialLaunchDatePreference = retrieveAccessor(forToken: .initialLaunchDate)
        if !(initialLaunchDatePreference.hasObject) {
            initialLaunchDatePreference.date = Date()
        }
    }
    
    func migrate() {
        migrate(
            keys: [
                "initialLaunchDate", "server", "installationID", "deviceLiveToken",
                "deviceVoipToken", "activeLocale", "vibroEnabled", "initialLoginAttempt",
                "lastDownAt", "chatNewSound", "chatMessageSound", "groupMessageSound",
                "chatLostSound", "sessionBreakSound", "worktimeSound", "systemPushSoundEnabled",
                "repeatUnreadNotificationsEnabled", "notificationStyle", "isOnline",
                "quickEmojis", "quickAnswers", "preferredCallerIndex", "preferredJournalLevel",
                "lastInformedFeature", "preferredQuickPhraseTag", "quickLinks",
                "recentExceptionMeta", "recentInterfaceState"
            ]
        )
    }
    
    func clearForReview() {
        retrieveAccessor(forToken: .initialLaunchDate).erase()
        retrieveAccessor(forToken: .initialLoginAttempt).erase()
    }
    
    func clearValuable() {
        retrieveAccessor(forToken: .server).erase()
        retrieveAccessor(forToken: .installationID).erase()
        retrieveAccessor(forToken: .deviceLiveToken).erase()
        retrieveAccessor(forToken: .activeLocale).erase()
        retrieveAccessor(forToken: .vibroEnabled).boolean = true
        retrieveAccessor(forToken: .initialLaunchDate).erase()
        retrieveAccessor(forToken: .initialLoginAttempt).erase()
        retrieveAccessor(forToken: .lastDownAt).erase()
        retrieveAccessor(forToken: .chatNewSound).sound = .standard
        retrieveAccessor(forToken: .chatMessageSound).sound = .standard
        retrieveAccessor(forToken: .chatLostSound).sound = .standard
        retrieveAccessor(forToken: .sessionBreakSound).sound = .standard
        retrieveAccessor(forToken: .systemPushSoundEnabled).erase()
        retrieveAccessor(forToken: .repeatUnreadNotificationsEnabled).erase()
        retrieveAccessor(forToken: .isOnline).boolean = true
        retrieveAccessor(forToken: .quickAnswers).erase()
        retrieveAccessor(forToken: .preferredCallerIndex).erase()
        retrieveAccessor(forToken: .preferredJournalLevel).journalLevel = .full
    }
    
    private func notifyQuickAnswers() {
//        quickAnswersObserver.broadcast(quickAnswers)
    }
}

extension IPreferencesAccessor {
    var sound: DevicePlaybackSound {
        get { string.flatMap(DevicePlaybackSound.init) ?? .standard }
        set { string = newValue.rawValue }
    }
    
    var journalLevel: JournalLevel {
        get { string.flatMap(JournalLevel.init) ?? .full }
        set { string = newValue.rawValue }
    }
}
