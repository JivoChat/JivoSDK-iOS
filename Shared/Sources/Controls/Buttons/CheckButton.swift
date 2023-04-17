//
//  CheckButton.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 18.11.2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import UIKit


final class CheckButton: UIButton {
    var tapHandler: (() -> Void)?
    
    private var additionalState: UIControl.State = [] {
        didSet { setNeedsLayout() }
    }
    
    init() {
        super.init(frame: .zero)
        
        setImage(UIImage(named: "check-mini-off"), for: .normal)
        setImage(UIImage(named: "check-mini-on"), for: .selected)
        setImage(UIImage(named: "check-mini-warn"), for: .application)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func warn() {
        additionalState = .application
    }
    
    override var state: UIControl.State {
        return super.state.union(additionalState)
    }
    
    override var isSelected: Bool {
        didSet { additionalState = [] }
    }
    
    @objc private func handleTap() {
        isSelected.toggle()
        tapHandler?()
    }
}
