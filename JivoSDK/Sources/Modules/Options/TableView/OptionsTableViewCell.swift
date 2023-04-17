//
//  OptionsTableViewCell.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 03.12.2020.
//

import UIKit
#if canImport(JivoFoundation)
import JivoFoundation
#endif
import CollectionAndTableViewCompatible


class OptionsTableViewCell: UITableViewCell, Configurable {
    
    // MARK: - Public properties
    
    var model: OptionsCellModel?

    // MARK: - Private properties
    
    fileprivate var colorView: UIView!
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        commonInit()
    }
    
    required init?(coder aCoder: NSCoder) {
        super.init(coder: aCoder)
        
        commonInit()
    }
    
    private func commonInit() {
        applyStyle()
        
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewDidTap(_:)))
//        addGestureRecognizer(tapGestureRecognizer)
    }

    // MARK: - Public methods
    
    func configure(withModel model: OptionsCellModel) {
        self.model = model
        
        textLabel?.text = model.title
        imageView?.image = model.icon?.withRenderingMode(.alwaysTemplate)
    }

    // MARK: - Private methods

    @objc private func viewDidTap(_ sender: UIView) {
        model?.tapHandler?()
    }
    
    // MARK: - Styling
    
    private func applyStyle() {
        backgroundColor = .clear
        
        textLabel?.textColor = JVDesign.colors.resolve(usage: .primaryForeground)
        textLabel?.font = obtainCaptionFont()
        
        imageView?.tintColor = JVDesign.colors.resolve(usage: .primaryForeground)
    }
}

fileprivate func obtainCaptionFont() -> UIFont {
    return JVDesign.fonts.resolve(.regular(16), scaling: .callout)
}
