//
//  ChatReplyControl.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 08.10.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import UIKit

final class SdkChatReplyControl: ChatGrowingSubmitControl<SdkChatReplyControl.Output> {
    private(set) lazy var menuButton = UIButton()
    
    init() {
        super.init(linesLimit: 1)
        
        backgroundColor = JVDesign.colors.resolve(usage: .primaryBackground)
        
        inputAreaContainer.backgroundColor = JVDesign.colors.resolve(usage: .slightBackground)
        
        inputArea.font = JVDesign.fonts.resolve(.regular(16), scaling: .callout)
        inputArea.textContainerInset = UIEdgeInsets(top: 13, left: 20, bottom: 13, right: 20)
        inputArea.placeholderOffset = CGPoint(x: 20, y: 0)
        inputArea.limit = SdkConfig.replyLengthLimit
        inputArea.tintColor = JVDesign.colors.resolve(usage: .focusedTint)
        inputArea.layer.masksToBounds = true
        
        menuButton.setImage(JVDesign.icons.find(asset: .attachIcon, rendering: .original), for: .normal)
        addSubview(menuButton)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleMenuButtonLongPress))
        longPressGesture.minimumPressDuration = 5
        menuButton.addGestureRecognizer(longPressGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func feed(update: Update) {
        if let input = update.input {
            switch input {
            case .active(let placeholder, let text, let menu):
                isUserInteractionEnabled = true
                
                if let placeholder = placeholder {
                    inputArea.placeholder = placeholder
                }
                
                if let text = text {
                    self.update(text: text)
                }
                
                if let menu = menu {
                    switch menu {
                    case .active:
                        menuButton.isHidden = false
                        menuButton.isEnabled = true
                    case .inactive:
                        menuButton.isHidden = false
                        menuButton.isEnabled = false
                    case .hidden:
                        menuButton.isHidden = true
                        menuButton.isEnabled = false
                    }
                    
                    setNeedsLayout()
                }
                
            case .inactive(let reason):
                self.update(text: .jv_empty)
                isUserInteractionEnabled = false
                
                if let reason = reason {
                    inputArea.placeholder = reason
                }
            }
        }
        
        if let submit = update.submit {
            switch submit {
            case .send:
                submitButton.setImage(JVDesign.icons.find(asset: .send_reply, rendering: .template), for: .normal)
                submitButton.setTitleColor(tintColor, for: .normal)
                submitButton.setTitleColor(JVDesign.colors.resolve(alias: .alto), for: .disabled)
                submitButton.jv_isBlinking = false
                
            case .connecting:
                submitButton.setImage(JVDesign.icons.find(asset: .send_network, rendering: .template), for: .normal)
                submitButton.setTitleColor(JVDesign.colors.resolve(usage: .secondaryForeground), for: .normal)
                submitButton.setTitleColor(JVDesign.colors.resolve(usage: .secondaryForeground), for: .disabled)
                submitButton.jv_isBlinking = true
            }
        }
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return inputArea.inputAccessoryView
        }
        set {
            inputArea.inputAccessoryView = newValue
        }
    }
    
    override var tintColor: UIColor! {
        didSet {
            inputArea.tintColor = tintColor
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        attachmentBar.frame = layout.attachmentBarFrame
        inputAreaContainer.frame = layout.textViewContainerFrame
        inputAreaContainer.layer.cornerRadius = layout.inputAreaCornerRadius
        inputArea.frame = layout.textViewFrame
        submitButton.frame = layout.sendButtonFrame
        menuButton.frame = layout.addAttachmentButtonFrame
    }
    
    fileprivate func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            attachmentBar: attachmentBar,
            inputArea: inputArea,
            shouldDisplayMenu: jv_not(menuButton.isHidden)
        )
    }
    
    @objc private func handleMenuButtonLongPress(_ sender: UIButton) {
        outputHandler(.extra(.menuLongPress(sender)))
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let attachmentBar: ChatReplyAttachmentBar
    let inputArea: ExtendedTextView
    let shouldDisplayMenu: Bool
    
    private let inputAreaHeightLimits: ClosedRange<CGFloat> = 44...100
    private let spacing = CGFloat(10)
    private let margin = CGFloat(12)
    private let edgeToTextGap = CGFloat(6)
    private let additionalAttachmentToTextGap = CGFloat(4)
    private let senderAvatarSize = CGSize(width: 30, height: 30)
    private let menuButtonTouchingSize = CGSize(width: 95, height: 95)
    private let submitButtonSize = CGSize(width: 70, height: 70)

    var addAttachmentButtonRealSize: CGSize {
        return shouldDisplayMenu ? menuButtonTouchingSize : .zero
    }
    
    var menuButtonSize: CGSize {
        if shouldDisplayMenu {
            let width = senderAvatarSize.width + spacing * 2
            let height = senderAvatarSize.height
            return CGSize(width: width, height: height)
        }
        else {
            return .zero
        }
    }
    
    var addAttachmentButtonFrame: CGRect {
        let origin = CGPoint(
            x: menuButtonSize.width * 0.5 - addAttachmentButtonRealSize.width * 0.5,
            y: inputAreaContainerSize.height * 0.5 - addAttachmentButtonRealSize.height * 0.5 + innerTopMargin
        )
        
        return CGRect(
            origin: origin,
            size: addAttachmentButtonRealSize
        )
    }
    
    var inputAreaContainerSize: CGSize {
        let spacing = shouldDisplayMenu ? self.spacing : self.spacing * 2
        let width = bounds.width - menuButtonSize.width - spacing
        let height = inputAreaHeightLimits.jv_clamp(value: inputArea.jv_height(forWidth: width))
        
        return CGSize(
            width: width,
            height: height
        )
    }
    
    var textViewContainerFrame: CGRect {
        return CGRect(
            origin: CGPoint(
                x: shouldDisplayMenu ? menuButtonSize.width : spacing,
                y: innerTopMargin
            ),
            size: inputAreaContainerSize
        )
    }
    
    var textViewFrame: CGRect {
        let size = textViewContainerFrame.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: submitButtonSize.width - 20)).size
        return CGRect(origin: .zero, size: size)
    }
    
    var inputAreaCornerRadius: CGFloat {
        return 44 * 0.5
    }
    
    var sendButtonFrame: CGRect {
        return CGRect(
            origin: CGPoint(
                x: textViewContainerFrame.maxX - submitButtonSize.width + 11,
                y: textViewContainerFrame.jv_center().y - submitButtonSize.height * 0.5
            ),
            size: submitButtonSize
        )
    }
    
    var attachmentBarFrame: CGRect {
        let width = bounds.width - margin * 2

        if attachmentBar.hasAttachments {
            let height = attachmentBar.jv_height(forWidth: width)
            return CGRect(x: margin, y: 13, width: width, height: height)
        }
        else {
            return CGRect(x: margin, y: 0, width: width, height: 0)
        }
    }
    
    var totalSize: CGSize {
        let height = inputAreaContainerSize.height
            .advanced(by: attachmentBar.hasAttachments ? 13 + attachmentBar.jv_height(forWidth: bounds.width - margin * 2) + additionalAttachmentToTextGap : 0)
        
        return CGRect(x: 0, y: 0, width: bounds.width, height: height)
            .insetBy(dx: 0, dy: -edgeToTextGap)
            .size
    }
    
    private var innerTopMargin: CGFloat {
        return edgeToTextGap
            .advanced(by: attachmentBar.hasAttachments ? attachmentBarFrame.maxY + additionalAttachmentToTextGap : 0)
    }
}
