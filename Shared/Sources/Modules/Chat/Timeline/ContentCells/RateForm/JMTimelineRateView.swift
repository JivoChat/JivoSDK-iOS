//
//  JMTimelineRateView.swift
//  JivoSDK
//
//  Created by Julia Popova on 09.10.2023.
//

import Foundation

class JMTimelineRateView: UIView, UIGestureRecognizerDelegate {
    var choiceSelected: ((Int) -> Void)?
    
    private struct UIConstants {
        static let buttonWidth = CGFloat(32)
        static let buttonHeight = CGFloat(32)
        static let defaultButtonPadding = CGFloat(30)
    }
    
    private var scale: ChatTimelineRateScale?
    
    private(set) var choice: Int? {
        didSet {
            if oldValue != choice {
                adjustActualState()
            }
        }
    }
    
    private let panGestureRecognizer = ImmediatePanGestureRecognizer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        panGestureRecognizer.addTarget(self, action: #selector(handlePan))
        self.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(scale: ChatTimelineRateScale, lastChoice: Int?) {
        subviews.forEach({ $0.removeFromSuperview() })
        self.scale = scale
        
        for id in scale.range {
            let button = JMTimelineRateButton(mark: scale.mark, total: scale.range.count, choice: id)
            addSubview(button)
        }
        
        choice = lastChoice
        adjustActualState()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let buttonPadding: CGFloat
        switch scale?.range.count {
        case .some(let number) where number >= 5:
            buttonPadding = (bounds.width - UIConstants.buttonWidth * CGFloat(number)) / CGFloat(number - 1)
        default:
            buttonPadding = UIConstants.defaultButtonPadding
        }
        
        let rateButtons = subviews
            .compactMap { $0 as? JMTimelineRateButton }
            .sorted { $0.choice < $1.choice }
        
        for (index, rateButton) in rateButtons.enumerated() {
            rateButton.frame = CGRect(
                x: CGFloat(index) * (UIConstants.buttonWidth + buttonPadding),
                y: 0,
                width: UIConstants.buttonWidth,
                height: UIConstants.buttonHeight)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsDisplay()
    }
    
    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        let point = sender.location(in: self)
        
        if let rateButton = subviews.compactMap({ $0 as? JMTimelineRateButton }).first(where: { $0.frame.contains(point) }) {
            choice = rateButton.choice
        }
        
        switch sender.state {
        case .ended, .cancelled:
            guard let choice = choice else { return }
            choiceSelected?(choice)
        default: break
        }
    }
    
    private func adjustActualState() {
        guard let scale = scale else {
            return
        }
        
        let rateButtons = subviews
            .compactMap { $0 as? JMTimelineRateButton }
            .sorted { $0.choice < $1.choice }
        
        for rateButton in rateButtons {
            if let rate = choice {
                if rateButton.choice > rate {
                    rateButton.isSelected = false
                } else if rateButton.choice == rate {
                    rateButton.isSelected = true
                } else {
                    rateButton.isSelected = scale.shouldHighlightLeadingMarks
                }
            } else {
                rateButton.isSelected = false
            }
        }
    }
}
