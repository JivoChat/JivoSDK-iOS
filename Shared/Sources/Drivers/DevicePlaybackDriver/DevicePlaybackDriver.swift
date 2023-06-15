//
//  DevicePlaybackDriver.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04/06/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import AVFoundation
import AudioToolbox
import UIKit


protocol IDevicePlaybackDriver: AnyObject {
    var currentOptions: DevicePlaybackOptions { get }
    func startupSession()
    func playerForFile(name: String, ext: String) -> DevicePlaybackAudioPlayer?
    func pushPlaybackOptions(_ options: DevicePlaybackOptions) -> Int
    func replacePlaybackOptions(_ options: DevicePlaybackOptions, priorityID: Int)
    func restorePlaybackOptions(after priotityID: Int)
    func updatePlayback(enabled: Bool)
    func playVibro(type: DevicePlaybackVibro)
    func enableBackgroundIfNeeded(reason: DevicePlaybackTurnoffReason)
    func disableBackgroundIfNeeded(reason: DevicePlaybackTurnoffReason)
}

final class DevicePlaybackDriver: IDevicePlaybackDriver {
    private var nextModeID = 0
    private let optionsQueue: PrioritizedQueueTool<DevicePlaybackOptions>
    private let optionsObservable = JVBroadcastTool<PrioritizedQueueItem<DevicePlaybackOptions>?>()
    private var backgroundTask = UIBackgroundTaskIdentifier.invalid

    private let notificationHaptic = UINotificationFeedbackGenerator()
    private var optionsObserver: JVBroadcastObserver<PrioritizedQueueItem<DevicePlaybackOptions>?>?

    init() {
        optionsQueue = PrioritizedQueueTool<DevicePlaybackOptions>(observable: optionsObservable)

        optionsQueue.schedule(
            item: PrioritizedQueueItem(
                priority: PrioritizedQueuePriority(rawValue: nextModeID),
                beginTime: Date(),
                endTime: nil,
                payload: [])
        )

        optionsObserver = optionsObservable.addObserver { [weak self] _ in
            self?.configurePlayback()
        }
    }
    
    var currentOptions: DevicePlaybackOptions {
        if let options = optionsQueue.findCurrentItem()?.payload {
            return options
        }
        else {
            /**
             This could happen if the app was launched,
             and then the system clock was set to an earlier date
             */
            
            return []
        }
    }

    func startupSession() {
        journal {"{device-playback-driver} ::startup-session"}
        
        let currentItem = optionsQueue.findCurrentItem()
        if let item = currentItem, item.payload.contains(.voip) {
            journal {"{device-playback-driver} ::startup-session skip-for-voip"}
            return
        }
        else {
            journal {"{device-playback-driver} ::startup-session current-option[\(String(describing: currentItem?.payload))]"}
        }
        
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: .mixWithOthers)
        try? session.overrideOutputAudioPort(.speaker)
    }
    
    func playerForFile(name: String, ext: String) -> DevicePlaybackAudioPlayer? {
//        guard not(AppConfig.isSimulator) else {
//            journal {"{device-playback-driver} ::player-for-file failure[disabled-for-simulator]"}
//            return nil
//        }
        
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            journal {"{device-playback-driver} ::player-for-file failure[resource-not-found]"}
            return nil
        }
        
        let player = try? DevicePlaybackAudioPlayer(contentsOf: url)
        return player
    }
    
    func pushPlaybackOptions(_ options: DevicePlaybackOptions) -> Int {
        nextModeID += 1
        applyPlaybackOptions(priorityID: nextModeID, options: options)
        return nextModeID
    }

    func replacePlaybackOptions(_ options: DevicePlaybackOptions, priorityID: Int) {
        applyPlaybackOptions(priorityID: priorityID, options: options)
    }

    func restorePlaybackOptions(after priotityID: Int) {
        popAudioMode(priorityID: priotityID)
    }

    func updatePlayback(enabled: Bool) {
        let session = AVAudioSession.sharedInstance()
        
        if enabled {
            try? session.setActive(true)
        }
        else {
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
    
    func playVibro(type: DevicePlaybackVibro) {
        switch (detectVibroHardware(), type) {
        case (.classic, .impact):
            break
        case (.haptic, .impact(let style)):
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        case (.classic, _):
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        case (.haptic, .standard):
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        case (.haptic, .warning):
            notificationHaptic.notificationOccurred(.warning)
        case (.haptic, .failure):
            notificationHaptic.notificationOccurred(.error)
        }
    }
    
    func enableBackgroundIfNeeded(reason: DevicePlaybackTurnoffReason) {
        guard reason == .backgroundMode else { return }
        guard backgroundTask == .invalid else { return }
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.disableBackground()
        }
    }
    
    func disableBackgroundIfNeeded(reason: DevicePlaybackTurnoffReason) {
        guard reason == .backgroundMode else { return }
        disableBackground()
        configurePlayback()
    }
    
    private func detectVibroHardware() -> DevicePlaybackHardwareType {
        if let support = UIDevice.current.value(forKey: "_feedbackSupportLevel") as? Int, support >= 2 {
            return .haptic
        }
        else {
            return .classic
        }
    }
    
    private func applyPlaybackOptions(priorityID: Int, options: DevicePlaybackOptions) {
        journal {"{device-playback-driver} ::apply-playback @priority[\(priorityID)] @options[\(options)]"}
        let priority = PrioritizedQueuePriority(rawValue: priorityID)
        
        optionsQueue.schedule(
            item: PrioritizedQueueItem(
                priority: priority,
                beginTime: Date(),
                endTime: nil,
                payload: options)
        )
    }

    private func popAudioMode(priorityID: Int) {
        journal {"{device-playback-driver} ::pop-audio-mode @priority[\(priorityID)]"}
        
        let priority = PrioritizedQueuePriority(rawValue: priorityID)
        optionsQueue.discard(priority: priority)
    }

    private func configurePlayback() {
        journal {"{device-playback-driver} ::configure-playback"}
        
        let options: DevicePlaybackOptions
        if let value = optionsQueue.findCurrentItem()?.payload {
            options = value
        }
        else {
            journal {"{device-playback-driver} ::configure-playback use-none-rules"}
            options = []
            return // assertionFailure()
        }
        
        if options.contains(.nested) {
            journal {"{device-playback-driver} ::configure-playback use-nesting-rules"}
            return
        }
        else if options.contains(.voip) {
            journal {"{device-playback-driver} ::configure-playback use-voip-rules"}
            return
        }
        else {
            journal {"{device-playback-driver} ::configure-playback do-configure options[\(options)]"}
        }

        let category: AVAudioSession.Category = (
            options.contains(.playback) ? .playAndRecord : .ambient
        )
        
        let mode: AVAudioSession.Mode = (
            options.contains(.voice) ? .spokenAudio : .default
        )
        
        let categoryOptions: AVAudioSession.CategoryOptions = (
            AVAudioSession.CategoryOptions(rawValue: 0)
                .union(options.contains(.quite) ? [] : .defaultToSpeaker)
                .union(options.contains(.exclusive) ? .duckOthers : .mixWithOthers)
                .union([.allowBluetooth, .allowBluetoothA2DP])
        )

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(category, mode: mode, options: categoryOptions)
    }
    
    private func disableBackground() {
        guard backgroundTask != .invalid
        else {
            return
        }
        
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}
