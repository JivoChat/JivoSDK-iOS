//
//  StackView.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04.10.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation

import UIKit

protocol StackViewHitDelegate: AnyObject {
    func stackViewHasHitLogic() -> Bool
    func stackView(_ stackView: UIView, hitPoint: CGPoint, event: UIEvent?, fallback: UIView?) -> UIView?
}

final class StackView: UIView {
    weak var hitDelegate: StackViewHitDelegate?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let original = super.hitTest(point, with: event)
        
        guard let hitDelegate = hitDelegate else {
            return original
        }
        
        if hitDelegate.stackViewHasHitLogic() {
            return hitDelegate.stackView(self, hitPoint: point, event: event, fallback: original)
        }
        else {
            return original
        }
    }
}
