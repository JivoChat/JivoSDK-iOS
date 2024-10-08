//
//  JMTimelineCompositeEventPhotoBlock.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMImageLoader
import JMTimelineKit
import AVFoundation
import SwiftMime

extension Notification.Name {
    static let messagePhotoTap = Notification.Name("messagePhotoTap")
}

struct JMTimelineCompositePhotoStyle: JMTimelineStyle {
    let ratio: CGFloat
    let contentMode: UIView.ContentMode
    let decorationColor: UIColor?
    let corners: CACornerMask
}

final class JMTimelineCompositePhotoBlock: JMTimelineBlock {
    private let underlayView = UIView()
    private let waitingIndicator = UIActivityIndicatorView(style: .jv_auto)
    
    private var ratio = CGFloat(1.0)
    private var decorationColor: UIColor?
    
    private var renderer: (UIView & Renderer)?
    private weak var decoration: UIView?
    private var originalUrl: URL?
    private var resource: RemoteStorageFileResource?
    private var originalSize: CGSize?
    private var cropped = false
    private var allowFullscreen = true
    private var style: JMTimelineCompositePhotoStyle!
    
    private let errorRendererConfiguration: ErrorRendererConfiguration
    
    init(errorRendererConfiguration: ErrorRendererConfiguration) {
        self.errorRendererConfiguration = errorRendererConfiguration
        
        super.init()
        
        layer.cornerRadius = Self.defaultCornerRadius
        clipsToBounds = true
        accessibilityIgnoresInvertColors = true

        underlayView.backgroundColor = JVDesign.colors.resolve(usage: .chattingBackground)
        underlayView.layer.cornerRadius = 13
        underlayView.clipsToBounds = true
        addSubview(underlayView)
        
        waitingIndicator.hidesWhenStopped = true
        addSubview(waitingIndicator)
        
        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleTap))
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(url: URL, originalSize: CGSize, cropped: Bool, allowFullscreen: Bool, style: JMTimelineCompositePhotoStyle, provider: JVChatTimelineProvider, interactor: JVChatTimelineInteractor) {
        self.originalUrl = url
        self.resource = nil
        self.originalSize = originalSize
        self.cropped = cropped
        self.allowFullscreen = allowFullscreen
        
        ratio = style.ratio
        contentMode = style.contentMode
        layer.maskedCorners = style.corners
        
        decorationColor = style.decorationColor
        decoration?.tintColor = decorationColor

        linkTo(provider: provider, interactor: interactor)
        
        renderer?.reset()
        waitingIndicator.startAnimating()
        
        let canvasWidth = originalSize.width * UIScreen.main.scale
        provider.retrieveResource(from: url, canvasWidth: canvasWidth) { [weak self] resource in
            guard let `self` = self, url == self.originalUrl else {
                return
            }
            
            guard let resource = resource else {
                self.waitingIndicator.startAnimating()
                self.renderer?.reset()
                return
            }
            
            self.resource = resource
            
            switch resource {
            case .value(_, .image(let image)):
                self.ensureRenderer(NativeRenderer.self).configure(image: image)
            case .value(let meta, .video):
                self.ensureRenderer(VideoRenderer.self).configure(url: meta.localUrl) { _ in }
            case let .failure(error):
                self.ensureRenderer(ErrorRenderer.self).configure(
                    image: self.errorRendererConfiguration.image,
                    errorDescription: self.errorRendererConfiguration.errorDescriptionProvider(error),
                    style: self.errorRendererConfiguration.style)
            default:
                break
            }
            
//            switch resource {
//            case .raw(let data) where NSData.sd_imageFormat(forImageData: data) == .undefined:
//                self.ensureRenderer(VideoRenderer.self).configure(data: data)
////                self.ensureRenderer(NativeRenderer.self).configure(data: data)
//            case .raw(let data):
//                self.ensureRenderer(UniversalRenderer.self).configure(data: data)
//            case .lottie(let animation):
//                self.ensureRenderer(LottieRenderer.self).configure(animation: animation)
//            case let .failure(errorDescription):
//                let style = ErrorRenderer.Style(backgroundColor: self.style.errorStubBackgroundColor, errorDescriptionColor: self.style.errorStubDescriptionColor)
//                let image = UIImage(named: "unavailable_image_stub", in: .auto, compatibleWith: nil)
//                self.ensureRenderer(ErrorRenderer.self).configure(image: image, errorDescription: errorDescription, style: style)
//            }
            
            self.waitingIndicator.stopAnimating()
        }
    }
    
    func reset() {
        originalUrl = nil
        resource = nil
        originalSize = nil
        renderer?.reset()
        waitingIndicator.stopAnimating()
    }
    
    override func updateDesign() {
    }
    
    override func handleLongPressGesture(recognizer: UILongPressGestureRecognizer) -> Bool {
        return false
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let originalSize = originalSize else {
            return .zero
        }
        
        let scale = UIScreen.main.scale
        
        if cropped {
            return originalSize
        }
        else if originalSize.width == 0 || originalSize.height == 0 {
            let height = size.width * ratio
            return CGSize(width: size.width, height: height)
        }
        else if (originalSize.width / scale) > size.width {
            let normalizedWidth = originalSize.width / scale
            let normalizedHeight = originalSize.height / scale
            let coef = size.width / normalizedWidth
            let width = normalizedWidth * coef
            let height = normalizedHeight * coef
            return CGSize(width: width, height: height)
        }
        else {
            let width = originalSize.width / scale
            let height = originalSize.height / scale
            return CGSize(width: width, height: height)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        underlayView.frame = bounds.insetBy(dx: 1, dy: 1)
        waitingIndicator.frame = bounds
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        if let _ = newWindow {
            renderer?.resume()
        }
        else {
            renderer?.pause()
        }
    }
    
    private func ensureRenderer<T: UIView & Renderer>(_ type: T.Type) -> T {
        if let element = renderer as? T {
            return element
        }
        
        let newElement = T.init()
        
        renderer?.removeFromSuperview()
        renderer = newElement
        renderer.flatMap(addSubview)
        
        renderer?.frame = bounds
        renderer?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
//        let decoration = DecorativeBorder()
//        decoration.frame = bounds
//        decoration.tintColor = decorationColor
//        decoration.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        renderer?.addSubview(decoration)
//        self.decoration = decoration

        return newElement
    }
    
    @objc private func handleTap() {
        guard case .some(.value(let meta, let kind)) = resource, allowFullscreen else {
            return
        }
        
        switch meta.purpose {
        case .origin:
            interactor?.requestMedia(url: meta.localUrl, kind: kind, mime: meta.mime) { _ in }
        case .preview:
            interactor?.requestMedia(url: meta.originUrl, kind: kind, mime: meta.mime) { _ in }
        }
    }
}

fileprivate final class DecorativeBorder: UIView {
    init() {
        super.init(frame: .zero)
        
        isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var tintColor: UIColor! {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        let clippingPath = UIBezierPath(
            roundedRect: rect.insetBy(dx: 2, dy: 2),
            cornerRadius: JVDesign.layout.timelineMessageRadius - 1
        )
        
        let parentPath = UIBezierPath(rect: rect)
        parentPath.append(clippingPath)
        parentPath.usesEvenOddFillRule = true
        
        tintColor?.setFill()
        parentPath.fill()
    }
}
