//
//  JMTimelineCompositeQuotingBlock.swift
//  App
//
//  Created by Stan Potemkin on 11.07.2023.
//

import Foundation
import UIKit
import TypedTextAttributes
import JMTimelineKit

struct JMTimelineCompositeQuotingStyle: JMTimelineStyle {
    let textColor: UIColor
}

final class JMTimelineCompositeQuotingBlock: UIView, JMTimelineBlockCallable {
    private let sideOffset: CGFloat
    
    private let indicator = UIView()
    private let previewImage = UIImageView()
    private let briefLabel = UILabel()
    
    private weak var interactor: JVChatTimelineInteractor?
    private var messageUid: String?
    
    init(sideOffset: CGFloat) {
        self.sideOffset = sideOffset
        
        super.init(frame: .zero)
        
        indicator.layer.cornerRadius = 1
        indicator.layer.masksToBounds = true
        addSubview(indicator)
        
        previewImage.layer.cornerRadius = 5
        previewImage.layer.masksToBounds = true
        addSubview(previewImage)
        
        briefLabel.backgroundColor = .clear
        briefLabel.numberOfLines = 2
        addSubview(briefLabel)
        
        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleTap))
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func link(provider: JMTimelineProvider, interactor: JMTimelineInteractor) {
    }
    
    func configure(message: MessageEntity?, style: JMTimelineCompositeQuotingStyle, interactor: JVChatTimelineInteractor) {
        self.interactor = interactor
        self.messageUid = message?.UUID
        
        indicator.backgroundColor = style.textColor.withAlphaComponent(0.4)
        
        if let message = message {
            let labelSlice = NSAttributedString(
                string: (message.sender?.displayName(kind: .original)).jv_orEmpty + "\n",
                attributes: TextAttributes()
                    .font(JVDesign.fonts.resolve(.medium(11), scaling: .subheadline))
                    .foregroundColor(style.textColor)
            )
            
            let preview: String
            switch message.content {
            case .photo(mime: _, name: _, let link, dataSize: _, width: _, height: _, title: _, text: _):
                preview = loc["Message.Preview.Photo"]
                
                if let url = URL(string: link) {
                    previewImage.jmLoadImage(with: url)
                    previewImage.isHidden = false
                }
            default:
                preview = message.text
                previewImage.isHidden = true
            }
            
            let previewSlice = NSAttributedString(
                string: preview,
                attributes: TextAttributes()
                    .font(JVDesign.fonts.resolve(.regular(11), scaling: .body))
                    .foregroundColor(style.textColor)
            )

            let content = NSMutableAttributedString()
            content.append(labelSlice)
            content.append(previewSlice)
            briefLabel.attributedText = content
        }
        else {
            briefLabel.text = nil
        }
        
        isHidden = not(briefLabel.jv_hasText)
    }
    
    func updateDesign() {
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        indicator.frame = layout.indicatorViewFrame
        previewImage.frame = layout.previewImageFrame
        briefLabel.frame = layout.briefLabelFrame
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            sideOffset: sideOffset,
            previewImage: previewImage,
            briefLabel: briefLabel
        )
    }
    
    func handleLongPressGesture(recognizer: UILongPressGestureRecognizer) -> Bool {
        return false
    }
    
    @objc private func handleTap() {
        guard let uid = messageUid else { return }
        interactor?.focusMessage(uid: uid)
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let sideOffset: CGFloat
    let previewImage: UIImageView
    let briefLabel: UILabel
    
    private let margins = UIEdgeInsets(top: 3, left: 0, bottom: 3, right: 0)
    private let contentHeight = CGFloat(25)
    
    var indicatorViewFrame: CGRect {
        return CGRect(
            x: margins.left + sideOffset,
            y: margins.top,
            width: 2,
            height: bounds.height - margins.vertical)
    }
    
    var previewImageFrame: CGRect {
        if previewImage.isHidden {
            return .zero
        }
        else {
            let leftX = indicatorViewFrame.maxX + 4
            return CGRect(x: leftX, y: margins.top, width: contentHeight, height: contentHeight)
        }
    }
    
    var briefLabelFrame: CGRect {
        let leftX = (previewImageFrame.maxX.isZero ? indicatorViewFrame.maxX : previewImageFrame.maxX) + 4
        let width = bounds.width - leftX - margins.right - sideOffset
        let size = briefLabel.jv_calculateSize(forWidth: width)
        return CGRect(x: leftX, y: margins.top, width: size.width, height: size.height)
    }
    
    var totalSize: CGSize {
        let width = briefLabelFrame.maxX + margins.right
        return CGSize(width: width, height: contentHeight + margins.vertical)
    }
}
