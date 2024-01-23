//
//  JMTimelineRateFormFieldControl.swift
//  JivoSDK
//
//  Created by Julia Popova on 15.10.2023.
//

import UIKit

final class JMTimelineRateFormFieldControl: UITextField {
    var title: String? {
        didSet {
            titleLabel.text  = title
        }
    }
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        label.textColor = JVDesign.colors.resolve(.usage(.secondaryForeground))
        label.isUserInteractionEnabled = false
        return label
    }()
    
    private lazy var bottomLine: UIView = {
        let bottomLine = UIView()
        bottomLine.backgroundColor = JVDesign.colors.resolve(usage: .secondarySeparator)
        bottomLine.frame = CGRect(x: 0, y: -1, width: 0, height: 1)
        bottomLine.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        bottomLine.isUserInteractionEnabled = false
        return bottomLine
    }()
    
    init() {
        super.init(frame: .zero)
        
        font = JVDesign.fonts.resolve(.medium(17), scaling: .callout)
        
        jv_addSubviews(children: titleLabel, bottomLine)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLabel.frame = CGRect(
            x: 0,
            y: 0,
            width: bounds.width,
            height: titleLabel.jv_calculateSize(forWidth: bounds.width).height
        )
    }
}
