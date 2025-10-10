//
//  JMTimelineRateFormControl.swift
//  JivoSDK
//
//  Created by Julia Popova on 26.09.2023.
//

import Foundation
import UIKit

enum JVMessageBodyRateFormStatus: String {
    case initial
    case rated
    case sent
    case dismissed
}

extension JMTimelineRateFormControl {
    enum Output {
        case change(_ choice: Int, comment: String)
        case submit(_ scale: ChatTimelineRateScale, choice: Int, comment: String)
        case close
    }
    
    typealias Sizing = JVMessageBodyRateFormStatus
}


final class JMTimelineRateFormControl: UIView, UITextFieldDelegate {
    var outputHandler: ((Output) -> Void)?
    
    var accentColor: UIColor? = JVDesign.colors.resolve(usage: .accentGreen) {
        didSet {
            accentColor = accentColor ?? JVDesign.colors.resolve(usage: .accentGreen)
            setNeedsDisplay()
        }
    }
    
    var sizing = Sizing.initial {
        didSet {
            setNeedsLayout()
        }
    }
    
    private var lastComment: String? {
        didSet {
            if let lastComment = lastComment {
                commentTextField.text = lastComment
            }
        }
    }
    
    var keyboardAnchorControl: KeyboardAnchorControl? {
        didSet { commentTextField.inputAccessoryView = keyboardAnchorControl }
    }
    
    private var lastChoice: Int?
    
    var rateConfig: JMTimelineRateConfig?
    
    var rateFormPreSubmitTitle: String?
    
    var rateFormPostSubmitTitle: String?
    
    var rateFormCommentPlaceholder: String?
    
    var rateFormSubmitCaption: String?
    
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.jv_named("close"), for: .normal)
        button.jv_contentEdgeInsets = UIEdgeInsets(jv_by: 11.0)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = JVDesign.fonts.resolve(.bold(14), scaling: .title3)
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = JVDesign.fonts.resolve(.regular(16), scaling: .body)
        label.numberOfLines = 0
        return label
    }()
    
    let rateView = JMTimelineRateView()
    
    private lazy var commentTextField: JMTimelineRateFormFieldControl = {
        let textField = JMTimelineRateFormFieldControl()
        textField.placeholder = nil
        textField.keyboardType = .default
        textField.delegate = self
        return textField
    }()
    
    private let sendButton = BigButton(type: .primary, sizing: .medium)
    
    init() {
        super.init(frame: .zero)
        
        isOpaque = false
        
        sendButton.shortTapHandler = { [weak self] in
            self?.handleSendButtonTap()
        }
        
        jv_addSubviews(children: closeButton, titleLabel, descriptionLabel, rateView, commentTextField, sendButton)
        
        rateView.clipsToBounds = true
        
        rateView.choiceSelected = { [weak self] selectedRate in
            guard let `self` = self else { return }
            let comment = self.sizing == .initial ? .jv_empty : commentTextField.text.jv_orEmpty
            lastChoice = selectedRate
            self.outputHandler?(.change(selectedRate, comment: comment))
        }
        
        closeButton.addTarget(self, action: #selector(handleCloseButtonTap), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let layout = getLayout(size: bounds.size)
        closeButton.frame = layout.closeButtonFrame
        titleLabel.frame = layout.titleLabelFrame
        descriptionLabel.frame = layout.descriptionLabelFrame
        rateView.frame = layout.rateViewFrame
        commentTextField.frame = layout.commentTextFieldFrame
        sendButton.frame = layout.sendButtonFrame
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let layout = getLayout(size: rect.size)
        
        let formRect = layout.decorationFrame.inset(by: layout.shadowOffsets)
        let formPath = UIBezierPath(roundedRect: formRect, cornerRadius: 10).cgPath
        
        context.addPath(formPath)
        context.setLineWidth(0.5)
        context.setStrokeColor(JVDesign.colors.resolve(usage: .lightDimmingShadow).cgColor)
        context.strokePath()
        
        context.addPath(formPath)
        context.setFillColor(JVDesign.colors.resolve(usage: .primaryBackground).cgColor)
        context.setShadow(offset: CGSize(width: 0, height: -2), blur: 0, color: accentColor?.cgColor)
        context.fillPath()
        
        context.addPath(formPath)
        context.setFillColor(JVDesign.colors.resolve(usage: .primaryBackground).cgColor)
        context.setShadow(offset: CGSize(width: 0, height: 3), blur: 3.0, color: JVDesign.colors.resolve(usage: .lightDimmingShadow).cgColor)
        context.fillPath()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsDisplay()
    }
    
    func adjustControl(
        config: JMTimelineRateConfig?,
        accentColor: UIColor?,
        sizing: JMTimelineRateFormControl.Sizing,
        rate: Int?,
        lastComment: String?,
        rateFormPreSubmitTitle: String?,
        rateFormPostSubmitTitle: String?,
        rateFormCommentPlaceholder: String?,
        rateFormSubmitCaption: String?
    ) {
        self.lastChoice = rate
        self.sizing = sizing
        self.rateConfig = config
        self.accentColor = accentColor
        self.rateFormPreSubmitTitle = rateFormPreSubmitTitle
        self.rateFormPostSubmitTitle = rateFormPostSubmitTitle
        self.rateFormCommentPlaceholder = rateFormCommentPlaceholder
        self.rateFormSubmitCaption = rateFormSubmitCaption
        
        if let rateConfig = rateConfig {
            rateView.configure(
                scale: rateConfig.scale,
                lastChoice: lastChoice
            )
        }
        
        switch sizing {
        case .initial:
            titleLabel.text = rateFormPreSubmitTitle
            descriptionLabel.text = config?.customRateTitle ?? loc["JV_RateForm_HeaderSubtitle_BeforeSubmission", "rate_form.description"]
        case .rated:
            titleLabel.text = rateFormPreSubmitTitle
            descriptionLabel.text = config?.customRateTitle ?? loc["JV_RateForm_HeaderSubtitle_BeforeSubmission", "rate_form.description"]
            commentTextField.title = rateFormCommentPlaceholder
            commentTextField.text = lastComment.jv_orEmpty
            sendButton.caption = rateFormSubmitCaption ?? loc["JV_RateForm_SubmitButton_Caption", "rate_form.send"]
        case .sent:
            titleLabel.text = rateFormPostSubmitTitle
            if let rate = rate, let config = config {
                if config.scale.shouldTakeAsPositive(choice: rate) {
                    descriptionLabel.text = config.goodRateTitle ?? loc["JV_RateForm_HeaderSubtitle_PositiveSubmission", "rate_form.finish_description_good"]
                } else {
                    descriptionLabel.text = config.badRateTitle ?? loc["JV_RateForm_HeaderSubtitle_NegativeSubmission", "rate_form.finish_description_bad"]
                }
            }
        case .dismissed:
            break
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        switch sizing {
        case .rated:
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
                textField.becomeFirstResponder()
            }
            return true
        default:
            return false
        }
    }
    
    internal func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let lastRate = lastChoice else { return true }
        if case .sent = sizing { return true }
        let finalString = NSString(string: textField.text.jv_orEmpty).replacingCharacters(in: range, with: string)
        outputHandler?(.change(lastRate, comment: finalString))
        return true
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            sizing: sizing,
            closeButton: closeButton,
            titleLabel: titleLabel,
            descriptionLabel: descriptionLabel,
            commentTextField: commentTextField,
            sendButton: sendButton
        )
    }
    
    @objc private func handleSendButtonTap() {
        guard let choice = rateView.choice,
              let scale = rateConfig?.scale
        else {
            return
        }
        
        let comment = commentTextField.text.jv_orEmpty
        outputHandler?(.submit(scale, choice: choice, comment: comment))
    }
    
    @objc private func handleCloseButtonTap() {
        outputHandler?(.close)
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let sizing: JMTimelineRateFormControl.Sizing
    let closeButton: UIButton
    let titleLabel: UILabel
    let descriptionLabel: UILabel
    let commentTextField: UITextField
    let sendButton: UIButton
    
    private let maxTotalWidth = CGFloat(320)
    private let horizontalMargin = CGFloat(24)
    private let horizontalPadding = CGFloat(16)

    private let spacing = CGFloat(8)
    
    var shadowOffsets: UIEdgeInsets {
        return UIEdgeInsets(top: 2, left: 0, bottom: 6, right: 0)
    }
    
    var innerMargins: UIEdgeInsets {
        return UIEdgeInsets(top: 14, left: 0, bottom: 20, right: 0)
    }
    
    var decorationFrameWidth: CGFloat {
         return bounds.width - (horizontalMargin * 2)
    }
    
    var contentWidth: CGFloat {
        bounds.width - (horizontalMargin * 2) - (horizontalPadding * 2)
    }
    
    var closeButtonFrame: CGRect {
        if case .dismissed = sizing {
            return .zero
        }
        
        let size = CGSize(width: 37.0, height: 37.0)
        
        return CGRect(
            x: decorationFrameWidth + horizontalMargin - size.width,
            y: 0,
            width: size.width,
            height: size.height
        )
    }
    
    var titleLabelFrame: CGRect {
        if case .dismissed = sizing {
            return .zero
        }
        
        return CGRect(
            x: horizontalMargin + horizontalPadding,
            y: horizontalPadding,
            width: contentWidth,
            height: titleLabel.jv_calculateSize(forWidth: contentWidth).height
        )
    }
    
    var descriptionLabelFrame: CGRect {
        if case .dismissed = sizing {
            return .zero
        }
        
        return CGRect(
            x: horizontalPadding + horizontalMargin,
            y: titleLabelFrame.maxY + spacing,
            width: contentWidth,
            height: descriptionLabel.jv_calculateSize(forWidth: contentWidth).height
        )
    }
    
    var rateViewFrame: CGRect {
        switch sizing {
        case .sent, .dismissed:
            return .init()
        case .rated, .initial:
            return CGRect(
                x: horizontalMargin + horizontalPadding,
                y: descriptionLabelFrame.maxY + 12.0,
                width: contentWidth,
                height: 32.0
            )
        }
    }
    
    var commentTextFieldFrame: CGRect {
        switch sizing {
        case .initial, .dismissed, .sent:
            return .init()
        case .rated:
            return CGRect(
                x: horizontalMargin + horizontalPadding,
                y: rateViewFrame.maxY + 24.0,
                width: contentWidth,
                height: 46.0
            )
        }
    }
    
    var sendButtonFrame: CGRect {
        switch sizing {
        case .initial, .dismissed, .sent:
            return .zero
        case .rated:
            return CGRect(
                x: horizontalMargin + horizontalPadding,
                y: commentTextFieldFrame.maxY + spacing,
                width: contentWidth,
                height: 36.0
            )
        }
    }
    
    var decorationFrame: CGRect {
        var rect = CGRect(x: horizontalMargin, y: 0, width: bounds.width - (horizontalMargin * 2), height: 0)
        
        switch sizing {
        case .initial: rect.size.height = rateViewFrame.maxY + innerMargins.bottom + shadowOffsets.bottom
        case .rated: rect.size.height = sendButtonFrame.maxY + innerMargins.bottom + shadowOffsets.bottom
        case .sent: rect.size.height = descriptionLabelFrame.maxY + innerMargins.bottom + shadowOffsets.bottom
        case .dismissed: rect.size.height = 0
        }
        return rect
    }
    
    var totalSize: CGSize {
        let height = decorationFrame.maxY
        return CGSize(width: bounds.width, height: height)
    }
}
