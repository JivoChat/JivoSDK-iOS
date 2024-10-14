//
//  JMTimelineDeliveryView.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 30/07/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMTimelineKit

final class JMTimelineDeliveryView: UIView {
    private let statusImage = UIImageView()
    private var channelsImages = [UIImageView]()
    
    init() {
        super.init(frame: .zero)
        
        statusImage.contentMode = .scaleAspectFit
        addSubview(statusImage)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(delivery: JMTimelineItemDelivery, icons: [UIImage]) {
        switch delivery {
        case .hidden:
            statusImage.image = nil
        case .queued:
            statusImage.image = UIImage(named: "message_queued", in: Bundle(for: JVDesign.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .sent:
            statusImage.image = UIImage(named: "message_sent", in: Bundle(for: JVDesign.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .delivered:
            statusImage.image = UIImage(named: "message_sent", in: Bundle(for: JVDesign.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .seen:
            statusImage.image = UIImage(named: "message_seen", in: Bundle(for: JVDesign.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .failed:
            statusImage.image = UIImage(named: "message_failed", in: Bundle(for: JVDesign.self), compatibleWith: nil)
        }
        
        if icons.count == channelsImages.count {
            zip(channelsImages, icons).forEach { imageView, icon in
                let image: UIImage = icon.withRenderingMode(.alwaysTemplate)
                imageView.image = image
                imageView.contentMode = .scaleAspectFit
            }
        }
        else {
            channelsImages.forEach {
                $0.removeFromSuperview()
            }
            
            channelsImages = icons.map {
                let iv = UIImageView(image: $0.withRenderingMode(.alwaysTemplate))
                iv.contentMode = .scaleAspectFit
                return iv
            }
            
            channelsImages.forEach {
                addSubview($0)
            }
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        statusImage.frame = layout.statusImageFrame
        zip(channelsImages, layout.channelsImagesFrames).layout()
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            statusImage: statusImage,
            channelsImages: channelsImages
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let statusImage: UIImageView
    let channelsImages: [UIImageView]
    
    private let generalHeight = CGFloat(14)
    private let horizontalGap = CGFloat(3)
    
    var statusImageFrame: CGRect {
        let size = statusImage.sizeThatFits(.zero)
        let topY = bounds.midY - generalHeight * 0.5
        let leftX = bounds.maxX - size.width
        return CGRect(x: leftX, y: topY, width: size.width, height: generalHeight)
    }
    
    var channelsImagesFrames: [CGRect] {
        let anchorFrame = statusImageFrame
        var rect = CGRect(x: anchorFrame.minX, y: 0, width: 0, height: 0)
        return channelsImages.map { image in
            rect.origin.x -= rect.width
            rect.size = image.sizeThatFits(.zero)
            rect.size.width *= anchorFrame.height / generalHeight
            rect.size.height = anchorFrame.height
            rect.origin.y = anchorFrame.minY
            rect.origin.x = rect.minX - rect.width - horizontalGap
            return rect
        }
    }
    
    var totalSize: CGSize {
        let frames = channelsImagesFrames + [statusImageFrame]
        let width = frames.jv_summarizeDimension(by: \.width, gap: horizontalGap)
        return CGSize(width: width, height: generalHeight)
    }
}
