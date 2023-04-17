//
//  DevicePlaybackAudioPlayer.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 24/02/2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation

import AVFoundation

final class DevicePlaybackAudioPlayer: AVAudioPlayer {
    var name = String()
    var isRemote = false
    private(set) var contextID = 0

    func play(contextID: Int) -> Bool {
        self.contextID = contextID
        return super.play()
    }

    override func play() -> Bool {
        abort()
    }
}
