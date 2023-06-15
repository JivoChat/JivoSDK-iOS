//
// Created by Stan Potemkin on 09/08/2018.
// Copyright (c) 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMTimelineKit

struct JMTimelineLoaderStyle: JMTimelineStyle {
    let waitingIndicatorStyle: UIActivityIndicatorView.Style
    
    init(waitingIndicatorStyle: UIActivityIndicatorView.Style) {
        self.waitingIndicatorStyle = waitingIndicatorStyle
    }
}

struct JMTimelineLoaderInfo: JMTimelineInfo {
    init() {
    }
}

final class JMTimelineLoaderItem: JMTimelinePayloadItem<JMTimelineLoaderInfo> {
}
