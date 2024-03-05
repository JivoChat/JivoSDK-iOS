//
//  JMTimelineCompositeVideoBlock.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMImageLoader
import JMTimelineKit

struct JMTimelineCompositeVideoStyle {
    let backgroundColor: UIColor
    let dimmingColor: UIColor
    let playBackgroundColor: UIColor
    let playIcon: UIImage
    let playTintColor: UIColor
    let ratio: CGFloat
}

final class JMTimelineCompositeVideoBlock: JMTimelineBlock {
    private let internalControl = InternalControl()
    
    private var url: URL?
    private var ratio = CGFloat(1.0)
    
    private let dimView = UIView()
    private let playIcon = UIImageView()
    
    override init() {
        super.init()
        
        addSubview(internalControl)
        
        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleTap))
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(url: URL) {
        self.url = url
        
//        backgroundColor = style.backgroundColor
//        dimView.backgroundColor = style.dimmingColor
//        playIcon.backgroundColor = style.playBackgroundColor
//        playIcon.image = style.playIcon
//        playIcon.tintColor = style.playTintColor
//        ratio = style.ratio
        
        internalControl.jmLoadImage(with: url)
    }
    
    override func updateDesign() {
    }
    
    override func handleLongPressGesture(recognizer: UILongPressGestureRecognizer) -> Bool {
        return false
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return internalControl.sizeThatFits(size)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        internalControl.frame = bounds
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size)
        )
    }
    
    @objc private func handleTap() {
        guard let url = url else {
            return
        }
        
        interactor?.requestMedia(url: url, kind: nil, mime: nil) { _ in
        }
    }
}

fileprivate final class InternalControl: UIImageView {
    private var url: URL?
    private var ratio = CGFloat(1.0)
    
    private let dimView = UIView()
    private let playIcon = UIImageView()
    
    init() {
        super.init(frame: .zero)
        
        contentMode = .scaleAspectFill
        clipsToBounds = true
        isUserInteractionEnabled = true
        
        dimView.isUserInteractionEnabled = false
        addSubview(dimView)
        
        playIcon.contentMode = .center
        dimView.addSubview(playIcon)
        
        accessibilityIgnoresInvertColors = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func apply(style: JMTimelineStyle) {
        let style = style.convert(to: JMTimelineCompositeVideoStyle.self)
        
        backgroundColor = style.backgroundColor
        dimView.backgroundColor = style.dimmingColor
        playIcon.backgroundColor = style.playBackgroundColor
        playIcon.image = style.playIcon
        playIcon.tintColor = style.playTintColor
        ratio = style.ratio
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        dimView.frame = layout.dimViewFrame
        playIcon.frame = layout.playIconFrame
        playIcon.layer.cornerRadius = layout.playIconCornerRadius
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: size.width * ratio)
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size)
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    
    var dimViewFrame: CGRect {
        return bounds
    }
    
    var playIconFrame: CGRect {
        let size = CGSize(width: 40, height: 40)
        
        return CGRect(
            x: bounds.minX + (bounds.width - size.width) * 0.5,
            y: bounds.minY + (bounds.height - size.height) * 0.5,
            width: size.width,
            height: size.height
        )
    }
    
    var playIconCornerRadius: CGFloat {
        return playIconFrame.width * 0.5
    }
}
