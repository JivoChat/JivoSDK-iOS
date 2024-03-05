//
// Created by Stan Potemkin on 2019-03-07.
// Copyright (c) 2019 JivoSite. All rights reserved.
//

import Foundation
import UIKit

fileprivate enum ObservablePaths: String, CaseIterable {
    case frame = "frame"
    case center = "center"
}

final class KeyboardAnchorControl: UIView {
    @StaticAddressWrapper private static var kFrameObservingContext
    @StaticAddressWrapper private static var kCenterObservingContext

    private var observerInstalled = false
    
    var keyboardFrameChangedBlock: (_ keyboardVisible: Bool, _ keyboardFrame: CGRect) -> Void = { _, _ in }
    private(set) var keyboardFrame = CGRect.zero
    
    deinit {
        if observerInstalled {
            superview?.removeObserver(self, forKeyPath: ObservablePaths.frame.rawValue, context: Self.kFrameObservingContext)
            superview?.removeObserver(self, forKeyPath: ObservablePaths.center.rawValue, context: Self.kCenterObservingContext)
        }
    }
    
    var keyboardVisible: Bool {
        return (keyboardFrame.minY < UIScreen.main.bounds.height)
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        if observerInstalled {
            observerInstalled = false
            superview?.removeObserver(self, forKeyPath: ObservablePaths.frame.rawValue, context: Self.kFrameObservingContext)
            superview?.removeObserver(self, forKeyPath: ObservablePaths.center.rawValue, context: Self.kCenterObservingContext)
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        isUserInteractionEnabled = false
        
        superview?.addObserver(self, forKeyPath: ObservablePaths.frame.rawValue, options: .jv_empty, context: Self.kFrameObservingContext)
        superview?.addObserver(self, forKeyPath: ObservablePaths.center.rawValue, options: .jv_empty, context: Self.kCenterObservingContext)
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
