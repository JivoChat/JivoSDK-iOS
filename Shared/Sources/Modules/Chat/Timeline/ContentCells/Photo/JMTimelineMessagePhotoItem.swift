//
//  JMTimelineMessagePhotoItem.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import UIKit
import JMTimelineKit

struct JMTimelineMessagePhotoInfo: JMTimelineInfo {
    let quotedMessage: JVMessage?
    let url: URL
    let width: Int
    let height: Int
    let caption: String?
    let plainStyle: JMTimelineCompositePlainStyle?
    let contentMode: UIView.ContentMode
    let allowFullscreen: Bool
    let contentTint: UIColor
}

struct JMTimelinePhotoStyle: JMTimelineStyle {
    let waitingIndicatorStyle: UIActivityIndicatorView.Style
    let errorStubStyle: ErrorStubStyle
    let ratio: CGFloat
    let contentMode: UIView.ContentMode
    
    init(waitingIndicatorStyle: UIActivityIndicatorView.Style,
                errorStubStyle: ErrorStubStyle,
                ratio: CGFloat,
                contentMode: UIView.ContentMode) {
        self.waitingIndicatorStyle = waitingIndicatorStyle
        self.errorStubStyle = errorStubStyle
        self.ratio = ratio
        self.contentMode = contentMode
    }
}

extension JMTimelinePhotoStyle {
    struct ErrorStubStyle {
        let backgroundColor: UIColor
        let errorDescriptionColor: UIColor
        
        init(backgroundColor: UIColor,
                    errorDescriptionColor: UIColor) {
            self.backgroundColor = backgroundColor
            self.errorDescriptionColor = errorDescriptionColor
        }
    }
}

final class JMTimelineMessagePhotoItem: JMTimelineMessageItem {
}

extension JMTimelineMessagePhotoInfo {
    func scaleMeta(minimum: CGFloat = 0, maximum: CGFloat = 0) -> (size: CGSize, cropped: Bool) {
        let scaledWidth = CGFloat(width) / UIScreen.main.scale
        let scaledHeight = CGFloat(height) / UIScreen.main.scale
        let minimalSide = min(scaledWidth, scaledHeight)
        
        if minimalSide == 0 {
            return (.zero, false)
        }
        else if minimum > 0, minimalSide < minimum {
            let size = CGSize(width: minimum, height: minimum)
            return (size, true)
        }
        else if maximum > 0, minimalSide > maximum {
            let size = CGSize(width: maximum, height: maximum)
            return (size, true)
        }
        else {
            let size = CGSize(width: minimalSide, height: minimalSide)
            return (size, true)
        }
    }
}
