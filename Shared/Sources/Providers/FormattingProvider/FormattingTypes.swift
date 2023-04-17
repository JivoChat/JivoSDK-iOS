//
//  FormattingTypes.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 02/06/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation

enum FormattingDateStyle {
    case lastMessageDate
    case dayHeader
    case messageTime
    case playbackTime
    case filterDate
    case taskFireDate
    case taskFireTime
    case taskFireDateTime
    case taskFireRelative
    case worktime
}

enum FormattingIntervalStyle {
    case sessionDuration
    case timeToTermination
}
