//
//  DevicePlaybackTypes.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 01/06/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit

struct DevicePlaybackOptions: OptionSet {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }

    static let playback = DevicePlaybackOptions(rawValue: 1 << 0)
    static let voice = DevicePlaybackOptions(rawValue: 1 << 1)
    static let quite = DevicePlaybackOptions(rawValue: 1 << 2)
    static let exclusive = DevicePlaybackOptions(rawValue: 1 << 3)
    static let voip = DevicePlaybackOptions(rawValue: 1 << 4)
    static let nested = DevicePlaybackOptions(rawValue: 1 << 5)
}

struct DevicePlaybackTurnoffReason: OptionSet {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }

    static let selfcheck: DevicePlaybackTurnoffReason = []
    static let backgroundMode = DevicePlaybackTurnoffReason(rawValue: 1 << 0)
    static let activeCall = DevicePlaybackTurnoffReason(rawValue: 1 << 1)
    static var all: DevicePlaybackTurnoffReason { return [.backgroundMode, .activeCall] }

    var allowsKeepPlaying: Bool {
        return contains(.backgroundMode)
    }
    
    var preventsRouteChanging: Bool {
        return contains(.activeCall)
    }
}

enum DevicePlaybackSound: RawRepresentable, Hashable {
    case standard
    case none
    case item(Int)
    case callEnd
    
    static func allValues() -> [DevicePlaybackSound] {
        return [.standard, .none] + (0 ... 13).map(DevicePlaybackSound.item)
    }
    
    init(rawValue: String) {
        if rawValue == "none" {
            self = .none
        }
        else if rawValue == "standard" {
            self = .standard
        }
        else if rawValue.hasPrefix("item"), rawValue.count > 4 {
            let offset = rawValue.index(rawValue.startIndex, offsetBy: 4)
            if let index = Int(rawValue[offset...]) {
                self = .item(index)
            }
            else {
                self = .standard
            }
        }
        else {
            self = .standard
        }
    }
    
    var rawValue: String {
        switch self {
        case .none: return "none"
        case .standard: return "standard"
        case .item(let index): return "item\(index)"
        case .callEnd: return "call_end"
        }
    }
    
    var hashValue: Int {
        switch self {
        case .standard: return 1
        case .none: return 2
        case .item(let index): return index.hashValue
        case .callEnd: return "call_end".hashValue
        }
    }

    var soundName: (name: String, ext: String)? {
        switch self {
        case .standard: return nil
        case .none, .item: return (name: "j\(serverCode() - 1)", ext: "aiff")
        case .callEnd: return (name: "call_end", ext: "m4a")
        }
    }
    
    var localizedTitle: String {
        switch self {
        case .standard: return loc["Preferences.Sounds.Item.Standard"]
        case .none: return loc["Preferences.Sounds.Item.None"]
        case .item(let index): return loc["Preferences.Sounds.Item.\(index + 1)"]
        case .callEnd: abort()
        }
    }
    
    static func ==(lhs: DevicePlaybackSound, rhs: DevicePlaybackSound) -> Bool {
        switch (lhs, rhs) {
        case (.standard, .standard): return true
        case (.none, .none): return true
        case (.item(let index1), .item(let index2)): return index1 == index2
        case (.callEnd, .callEnd): return true
        default: return false
        }
    }
}

enum DevicePlaybackVibro {
    case warning
    case failure
    case standard
    case impact(style: UIImpactFeedbackGenerator.FeedbackStyle)
}

enum DevicePlaybackHardwareType {
    case classic
    case haptic
}

extension DevicePlaybackSound {
    func serverCode() -> Int {
        switch self {
        case .standard: return 0
        case .none: return 1
        case .item(let index): return index + 2
        case .callEnd: abort()
        }
    }
}
