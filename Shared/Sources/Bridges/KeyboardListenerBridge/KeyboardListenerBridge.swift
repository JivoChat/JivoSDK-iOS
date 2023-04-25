//
//  KeyboardListenerBridge.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JivoFoundation


protocol IKeyboardListenerBridge: AnyObject {
    var observable: JVBroadcastTool<KeyboardListenerNotification> { get }
    func keyboardMeta(for view: UIView, context: UIView?) -> KeyboardListenerMeta
    func keyboardHeight(for view: UIView, context: UIView?) -> CGFloat
    func animate(for view: UIView, context: UIView, block: @escaping (KeyboardListenerMeta) -> Void)
}

final class KeyboardListenerBridge: IKeyboardListenerBridge {
    let observable = JVBroadcastTool<KeyboardListenerNotification>()
    
    private var keyboardFrame = CGRect.zero
    private var keyboardDuration = TimeInterval(0)
    private var keyboardCurve = UInt(0)
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardNotification),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardNotification),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func keyboardMeta(for view: UIView, context: UIView?) -> KeyboardListenerMeta {
        if let context = context, context.findActiveResponder() == nil {
            return KeyboardListenerMeta(height: 0, duration: keyboardDuration)
        }
        
        let viewFrame = view.convert(view.bounds, to: nil)
        let height = viewFrame.intersection(keyboardFrame).height
        return KeyboardListenerMeta(height: height, duration: keyboardDuration)
    }
    
    func keyboardHeight(for view: UIView, context: UIView?) -> CGFloat {
        return keyboardMeta(for: view, context: context).height
    }
    
    func animate(for view: UIView, context: UIView, block: @escaping (KeyboardListenerMeta) -> Void) {
        let meta = keyboardMeta(for: view, context: context)
        let curveOption = UIView.AnimationOptions(rawValue: keyboardCurve << 16)
        
        UIView.animate(
            withDuration: keyboardDuration,
            delay: 0,
            options: [curveOption],
            animations: { block(meta) },
            completion: nil
        )
    }
    
    @objc private func handleKeyboardNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        keyboardFrame = userInfo.keyboardEndFrame()
        keyboardDuration = userInfo.keyboardAnimationDuration()
        keyboardCurve = userInfo.keyboardAnimationCurve()
        
        observable.broadcast(
            KeyboardListenerNotification(name: notification.name, frame: keyboardFrame)
        )
    }
}

fileprivate extension Dictionary where Key == AnyHashable, Value == Any {
    func keyboardEndFrame() -> CGRect {
        if let value = self[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            return value
        }
        else {
            return .zero
        }
    }
    
    func keyboardAnimationDuration() -> TimeInterval {
        if let value = self[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
            return value
        }
        else {
            return 0
        }
    }
    
    func keyboardAnimationCurve() -> UInt {
        if let value = self[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
            return value
        }
        else {
            return 0
        }
    }
}

fileprivate extension UIView {
    func findActiveResponder() -> UIResponder? {
        if isFirstResponder {
            return self
        }
        
        for child in subviews {
            guard let activeResponder = child.findActiveResponder() else { continue }
            return activeResponder
        }
        
        return nil
    }
}
