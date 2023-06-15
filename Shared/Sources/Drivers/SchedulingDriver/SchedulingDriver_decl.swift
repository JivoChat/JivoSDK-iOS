//
//  SchedulingDriverDecl.swift
//  App
//
//  Created by Stan Potemkin on 08.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

protocol ISchedulingCore: AnyObject {
    func trigger(delay: TimeInterval, target: Any, sel: Selector, userInfo: Any?, repeats: Bool) -> Timer
    func untrigger(timer: Timer)
}
