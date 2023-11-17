//
//  PopupPresenterFlexibleMenuConfigurator.swift
//  App
//
//  Created by Yulia Popova on 11.09.2023.
//

import Foundation

class PopupPresenterFlexibleMenuConfigurator {
    let items: [PopupPresenterFlexibleMenuItem]
    
    init(items: [PopupPresenterFlexibleMenuItem]) {
        self.items = items
    }
    
    func configure(
        button: UIButton,
        fallbackRecognizer: UIGestureRecognizer
    ) {
        button.addGestureRecognizer(fallbackRecognizer)
    }
    
    func reset(button: UIButton, fallbackRecognizer: UIGestureRecognizer?) {
        if let gesture = fallbackRecognizer {
            button.removeGestureRecognizer(gesture)
        }
    }
}
