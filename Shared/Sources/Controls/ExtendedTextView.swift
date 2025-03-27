//
//  ExtendedTextView.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 26/02/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit

protocol ResponderProxy {
    var isFirstResponder: Bool { get }
    func register(_ responder: UIResponder, for actions: [Selector])
}

final class ExtendedTextView: InputTextArea, UITextViewDelegate, ResponderProxy {
    private let placeholderLabel = UILabel()
    
    var limit: Int?
    var startEditingHandler: ((String) -> Void)?
    var textChangeHandler: ((String) -> Void)?
    var heightUpdateHandler: (() -> Void)?
    var finishEditingHandler: ((String) -> Void)?

    init(linesLimit: Int) {
        super.init()
        
        backgroundColor = UIColor.clear
        textColor = JVDesign.colors.resolve(usage: .primaryForeground)
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        delegate = self
        inputAccessoryView = UIView()
        
        placeholderLabel.textColor = JVDesign.colors.resolve(usage: .secondaryForeground).jv_withAlpha(0.45)
        placeholderLabel.numberOfLines = linesLimit
        placeholderLabel.lineBreakMode = (linesLimit == 1 ? .byTruncatingTail : .byWordWrapping)
        placeholderLabel.isUserInteractionEnabled = false
        addSubview(placeholderLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var font: UIFont? {
        didSet {
            placeholderLabel.font = font
        }
    }
    
    var placeholder: String? {
        get {
            return placeholderLabel.text
        }
        set {
            guard newValue != placeholderLabel.text else { return }
            placeholderLabel.text = newValue
            setNeedsLayout()
        }
    }
    
    var placeholderOffset: CGPoint = .zero {
        didSet {
            setNeedsLayout()
        }
    }
    
    override var text: String? {
        didSet {
            adjustTextColor()
            placeholderLabel.isHidden = hasText
        }
    }
    
    var isOverLimit: Bool {
        guard let limit = limit else { return false }
        guard let text = text else { return false }
        return (text.count > limit)
    }
    
    var caretPosition: Int? {
        let beginning = beginningOfDocument
        let end = endOfDocument
        
        if let range = selectedTextRange {
            return offset(from: beginning, to: range.start)
        }
        else {
            return hasText ? offset(from: beginning, to: end) - 1 : nil
        }
    }
    
    func insertAtCaret(symbol: String, replacement: String) {
        guard let content = text else {
            text = replacement
            return
        }
        
        guard let range = selectedTextRange else {
            text = content + symbol + replacement
            return
        }
        
        let searchingRange = NSMakeRange(0, offset(from: beginningOfDocument, to: range.start))
        let foundRange = (content as NSString).range(of: symbol, options: .backwards, range: searchingRange, locale: nil)
        
        guard foundRange.location != NSNotFound else {
            replace(range, withText: symbol + replacement)
            return
        }
        
        guard let startPosition = position(from: beginningOfDocument, offset: foundRange.upperBound) else {
            replace(range, withText: symbol + replacement)
            return
        }
        
        guard let replacingRange = textRange(from: startPosition, to: range.end) else {
            replace(range, withText: symbol + replacement)
            return
        }
        
        if let tail = text(in: replacingRange), tail.jv_containsSymbols(from: .mentioningGap) {
            replace(range, withText: symbol + replacement)
            return
        }
            
        replace(replacingRange, withText: replacement)
    }
    
    override func insertText(_ text: String) {
        super.insertText(text)
        adjustTextColor()
    }
    
    func register(_ responder: UIResponder, for actions: [Selector]) {
//        textView.register(responder, for: actions)
    }
    
    func calculateContentOffset(for maxHeight: CGFloat) -> CGFloat? {
        return jv_calculateContentOffset(for: maxHeight)
    }
    
    func calculateSize(for width: CGFloat, numberOfLines: Int?) -> CGSize {
        return jv_calculateSize(for: width, numberOfLines: numberOfLines)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if placeholderOffset == .zero {
            let size = placeholderLabel.jv_calculateSize(forWidth: bounds.width)
            placeholderLabel.frame = CGRect(x: 0, y: (bounds.height - size.height) * 0.5 - 1, width: size.width, height: size.height)
        }
        else {
            let size = placeholderLabel.jv_calculateSize(forWidth: bounds.divided(atDistance: placeholderOffset.x, from: .minXEdge).remainder.width)
            placeholderLabel.frame = CGRect(x: placeholderOffset.x, y: placeholderOffset.y - 1, width: size.width, height: max(bounds.height, size.height))
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let placeholderSize = placeholderLabel.sizeThatFits(size)
        let textViewSize = super.sizeThatFits(size)
        
        return CGSize(
            width: textViewSize.width,
            height: max(textViewSize.height, placeholderSize.height)
        )
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        startEditingHandler?(textView.text.jv_orEmpty)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = textView.hasText
        
        textChangeHandler?(textView.text.jv_orEmpty)
        
        if textView.jv_calculateSize(for: bounds.width, numberOfLines: nil).height != textView.bounds.height {
            heightUpdateHandler?()
        }
        
        adjustTextColor()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        finishEditingHandler?(textView.text.jv_orEmpty)
    }
    
    override func replace(_ range: UITextRange, withText: String) {
        super.replace(range, withText: withText)
        adjustTextColor()
    }
    
    private func adjustTextColor() {
        textColor = JVDesign.colors.resolve(usage: isOverLimit ? .warningForeground : .primaryForeground)
    }
}
