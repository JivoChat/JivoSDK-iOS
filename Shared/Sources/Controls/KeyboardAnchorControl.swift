//
// Created by Stan Potemkin on 2019-03-07.
// Copyright (c) 2019 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation
import UIKit

fileprivate var observingContext = UUID()

fileprivate enum ObservablePaths: String, CaseIterable {
    case frame = "frame"
    case center = "center"
}

final class KeyboardAnchorControl: UIView {
    private var observerInstalled = false
    
    var keyboardFrameChangedBlock: (_ keyboardVisible: Bool, _ keyboardFrame: CGRect) -> Void = { _, _ in }
    private(set) var keyboardFrame = CGRect.zero
    
    deinit {
        if observerInstalled {
            superview?.removeObserver(self, forKeyPath: ObservablePaths.frame.rawValue, context: &observingContext)
            superview?.removeObserver(self, forKeyPath: ObservablePaths.center.rawValue, context: &observingContext)
        }
    }
    
    var keyboardVisible: Bool {
        return (keyboardFrame.minY < UIScreen.main.bounds.height)
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        if observerInstalled {
            observerInstalled = false
            superview?.removeObserver(self, forKeyPath: ObservablePaths.frame.rawValue, context: &observingContext)
            superview?.removeObserver(self, forKeyPath: ObservablePaths.center.rawValue, context: &observingContext)
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        isUserInteractionEnabled = false
        
        superview?.addObserver(self, forKeyPath: ObservablePaths.frame.rawValue, options: .jv_empty, context: &observingContext)
        superview?.addObserver(self, forKeyPath: ObservablePaths.center.rawValue, options: .jv_empty, context: &observingContext)
        observerInstalled = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        syncKeyboardFrame()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (object as? AnyObject) === superview, ObservablePaths.allCases.map(\.rawValue).contains(keyPath.jv_orEmpty) {
            syncKeyboardFrame()
        }
    }
    
    private func syncKeyboardFrame() {
        keyboardFrame = superview?.frame.offsetBy(dx: 0, dy: bounds.height) ?? .zero
        keyboardFrameChangedBlock(keyboardVisible, keyboardFrame)
    }
}
