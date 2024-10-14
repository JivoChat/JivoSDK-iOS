//
//  JMTimelineChatResolvedControl.swift
//  App
//
//  Created by Julia Popova on 28.06.2024.
//

import UIKit

enum JVMessageBodyChatResolvedStatus: String {
    case initial
    case dismissed
}

extension JMTimelineChatResolvedControl {
    enum Output {
        case close
    }
    
    typealias Sizing = JVMessageBodyChatResolvedStatus
}


final class JMTimelineChatResolvedControl: UIView {
    var outputHandler: ((Output) -> Void)?
    
    var sizing = Sizing.initial {
        didSet {
            setNeedsLayout()
        }
    }
    
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "close", in: Bundle(for: JVDesign.self), compatibleWith: nil), for: .normal)
        button.setTitle("Close", for: .normal)
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
    
    private let sendButton = BigButton(type: .primary, sizing: .medium)
    
    init() {
        super.init(frame: .zero)
        
        isOpaque = false
        backgroundColor = .red

        sendButton.shortTapHandler = { [weak self] in
            self?.handleSendButtonTap()
        }
        
        jv_addSubviews(children: closeButton, titleLabel, descriptionLabel, sendButton)
        
        closeButton.addTarget(self, action: #selector(handleCloseButtonTap), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return .init(
            width: self.frame.width - 30.0,
            height: 50.0
        )
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        closeButton.frame = .init(
            origin: .init(
                x: 15.0,
                y: 15.0
            ),
            size: .init(
                width: self.frame.width - 30.0,
            height: 20.0
            )
        )
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsDisplay()
    }
    
    func adjustControl(
        sizing: JMTimelineChatResolvedControl.Sizing
    ) {
        switch sizing {
        case .initial:
            break
        case .dismissed:
            break
        }
    }
    
    @objc private func handleSendButtonTap() { }
    
    @objc private func handleCloseButtonTap() {
        outputHandler?(.close)
    }
}
