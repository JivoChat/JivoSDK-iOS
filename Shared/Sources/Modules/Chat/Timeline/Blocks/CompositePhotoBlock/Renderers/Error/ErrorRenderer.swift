//
//  ErrorRenderer.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 28.02.2022.
//  Copyright © 2022 jivosite.mobile. All rights reserved.
//

import UIKit
#if canImport(JivoFoundation)
import JivoFoundation
#endif

final class ErrorRenderer: UIView, Renderer {
    private lazy var contentView = UIView()
    private lazy var mainContainer = UIView()
    private lazy var imageView = UIImageView()
    private lazy var errorDescriptionLabel = UILabel()
    
    private var imageScale = CGFloat(1.0)
    
    func configure(image: UIImage?, errorDescription: String?, style: Style) {
        contentView.isHidden = false
        
        imageView.image = image
        imageView.tintColor = JVDesign.colors.resolve(usage: .secondaryForeground)
        
        errorDescriptionLabel.text = errorDescription
        
        imageScale = style.iconScale
        
        backgroundColor = style.backgroundColor
        errorDescriptionLabel.font = obtainFailureFont()
        errorDescriptionLabel.textColor = style.errorDescriptionColor
        errorDescriptionLabel.textAlignment = .center
        
        setUpSubviews()
    }
    
    func pause() {
    }
    
    func resume() {
    }

    func reset() {
        contentView.isHidden = true
    }
    
    override func layoutSubviews() {
        let layout = Layout(
            superView: self,
            contentView: contentView,
            imageView: imageView,
            imageScale: imageScale,
            errorDescriptionLabel: errorDescriptionLabel
        )
        
        contentView.frame = layout.contentViewFrame
        mainContainer.frame = layout.mainContainerFrame
        imageView.frame = layout.imageViewFrame
        errorDescriptionLabel.frame = layout.errorDescriptionFrame
    }
    
    private func setUpSubviews() {
        errorDescriptionLabel.numberOfLines = 0
        
        contentView.backgroundColor = .clear
        mainContainer.backgroundColor = .clear
        
        mainContainer.addSubview(imageView)
        mainContainer.addSubview(errorDescriptionLabel)
        contentView.addSubview(mainContainer)
        addSubview(contentView)
    }
}

extension ErrorRenderer {
    struct Style {
        let backgroundColor: UIColor
        let iconScale: CGFloat
        let errorDescriptionColor: UIColor
    }
    
    struct Layout {
        let superView: UIView
        let contentView: UIView
        let imageView: UIView
        let imageScale: CGFloat
        let errorDescriptionLabel: UIView
        
        var imageViewToErrorDescriptionLabelMargin: CGFloat {
            return 15
        }
        
        var errorDescriptionHMargin: CGFloat {
            return 15
        }
        
        var contentViewFrame: CGRect {
            return superView.bounds
        }
        
        var mainContainerFrame: CGRect {
            let mainContainerWidth = max(imageViewFrame.size.width, errorDescriptionFrame.size.width)
            let mainContainerHeight = imageViewFrame.size.height + imageViewToErrorDescriptionLabelMargin + errorDescriptionFrame.size.height
            let mainContainerSize = CGSize(width: mainContainerWidth, height: mainContainerHeight)
            
            let mainContaineFrameOriginX = contentView.center.x - mainContainerWidth / 2
            let mainContaineFrameOriginY = contentView.center.y - mainContainerHeight / 2
            let mainContainerFrameOrigin = CGPoint(x: mainContaineFrameOriginX, y: mainContaineFrameOriginY)
            
            return CGRect(origin: mainContainerFrameOrigin, size: mainContainerSize)
        }
        
        var imageViewFrame: CGRect {
            let imageViewSize = imageView.intrinsicContentSize
            let width = imageViewSize.width * imageScale
            let height = imageViewSize.height * imageScale
            let imageViewFrameOrigin = CGPoint(x: errorDescriptionSize.width / 2 - width / 2, y: .zero)
            return CGRect(origin: imageViewFrameOrigin, size: CGSize(width: width, height: height))
        }
        
        var errorDescriptionSize: CGSize {
            let errorDescriptionWidth = contentViewFrame.size.width - errorDescriptionHMargin * 2
            return errorDescriptionLabel.jv_size(forWidth: errorDescriptionWidth)
        }
        
        var errorDescriptionFrame: CGRect {
            let imageViewFrameOriginTranslationY = imageViewFrame.height + imageViewToErrorDescriptionLabelMargin
            let errorDescriptionFrameOrigin = CGPoint(x: .zero, y: imageViewFrameOriginTranslationY)
            
            return CGRect(origin: errorDescriptionFrameOrigin, size: errorDescriptionSize)
        }
    }
}

fileprivate func obtainFailureFont() -> UIFont {
    return JVDesign.fonts.resolve(.light(14), scaling: .subheadline)
}
