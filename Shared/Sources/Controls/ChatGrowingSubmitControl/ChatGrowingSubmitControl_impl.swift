//
//  GrowingSubmitControl-impl.swift
//  App
//
//  Created by Stan Potemkin on 28.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

class ChatGrowingSubmitControl<T>: UIView {
    var outputHandler: (ChatGrowingSubmitControlOutput<T>) -> Void = { _ in }
    
    let attachmentBar = ChatReplyAttachmentBar()
    let inputAreaContainer = UIView()
    let inputArea = ExtendedTextView()
    let submitButton = UIButton()

    init() {
        super.init(frame: .zero)
        
        addSubview(attachmentBar)
        
        inputAreaContainer.addSubview(inputArea)
        addSubview(inputAreaContainer)
        
        submitButton.addTarget(self, action: #selector(handleSubmitButtonTap), for: .touchUpInside)
        addSubview(submitButton)
        
        actualizeSubmitControls()
        
        attachmentBar.dismissTapHandler = { [weak self] index in
            self?.outputHandler(.discardAttachment(index))
        }
        
        inputArea.textChangeHandler = { [weak self] value in
            self?.handleInputChange(text: value)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(text: String) {
        guard text != inputArea.text
        else {
            return
        }
        
        inputArea.text = text
        handleInputChange(text: text)
    }
    
    func updateAttachments(objects: [ChatPhotoPickerObject]) {
        guard jv_not(objects.isEmpty)
        else {
            return
        }
        
        attachmentBar.isHidden = false
        for object in objects {
            attachmentBar.update(attachment: object)
        }
        
        actualizeSubmitControls()
        notifyAboutActualHeight()
    }
    
    func removeAttachment(at index: Int) {
        attachmentBar.remove(at: index)
        attachmentBar.isHidden = attachmentBar.hasAttachments
        
        actualizeSubmitControls()
        notifyAboutActualHeight()
    }
    
    func removeAttachments() {
        attachmentBar.removeAll()
        attachmentBar.isHidden = true
        
        actualizeSubmitControls()
        notifyAboutActualHeight()
    }
    
    func shakeAttachments() {
        let midX = attachmentBar.center.x
        let midY = attachmentBar.center.y
        
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.035
        animation.repeatCount = Float(4)
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: midX - 2.0, y: midY)
        animation.toValue = CGPoint(x: midX + 2.0, y: midY)
        attachmentBar.layer.add(animation, forKey: "position")
    }
    
    func actualizeSubmitControls() {
        submitButton.isEnabled = shouldAllowSubmitting()
    }
    
    func shouldAllowSubmitting() -> Bool {
        return inputArea.hasText
    }
    
    func handleInputChange(text: String) {
        actualizeSubmitControls()
        notifyAboutActualHeight()
        outputHandler(.text(value: text, caret: inputArea.caretPosition))
    }
    
    @discardableResult
    func notifyAboutActualHeight() -> Bool {
        let needHeight = jv_height(forWidth: bounds.width)
        
        if bounds.height != needHeight {
            setNeedsLayout()
            outputHandler(.height(needHeight))
            return true
        }
        else {
            return false
        }
    }
    
    @objc private func handleSubmitButtonTap() {
        outputHandler(.submit(inputArea.text.jv_orEmpty))
    }
}
