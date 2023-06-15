//
//  SdkSchedulingCore.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 01.10.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation

final class SdkSchedulingCore: ISchedulingCore {
    func trigger(delay: TimeInterval, target: Any, sel: Selector, userInfo: Any?, repeats: Bool) -> Timer {
        return Timer.scheduledTimer(
            timeInterval: delay,
            target: target,
            selector: sel,
            userInfo: userInfo,
            repeats: repeats)
    }
    
    func untrigger(timer: Timer) {
        timer.invalidate()
    }
}
