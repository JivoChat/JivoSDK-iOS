//
//  JMTimelineMessageLocationItem.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import CoreLocation
import JMTimelineKit

struct JMTimelineMessageLocationInfo: JMTimelineInfo {
    let coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

typealias JMTimelineLocationStyle = JMTimelineCompositeLocationBlockStyle

final class JMTimelineMessageLocationItem: JMTimelineMessageItem {
}
