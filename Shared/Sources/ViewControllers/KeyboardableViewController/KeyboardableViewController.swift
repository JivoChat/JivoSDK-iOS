//
//  KeyboardableViewController.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 14.03.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import UIKit

class KeyboardableViewController<Satellite: BaseViewControllerSatellite>: BaseViewController<Satellite> {
    private var keyboardObserver: JVBroadcastObserver<KeyboardListenerNotification>?
    
    internal var adjustableScrollView: UIScrollView {
        abort()
    }
    
    internal var adjustingDefaultInsets: UIEdgeInsets {
        return .zero
    }
    
    final var keyboardHeight: CGFloat {
        return satellite?.keyboardListenerBridge.keyboardHeight(for: adjustableScrollView, context: view) ?? 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        keyboardObserver = satellite?.keyboardListenerBridge.observable.addObserver { [unowned self] _ in
            guard self.isViewLoaded else { return }
            guard let _ = self.view.window else { return }
            
            self.view.setNeedsLayout()
            UIView.animate(withDuration: 0.25, animations: self.view.layoutIfNeeded)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let layout = getLayout(size: view.bounds.size)
        adjustableScrollView.contentInset = layout.scrollViewContentInsets
        if #available(iOS 11.1, *) {
            adjustableScrollView.verticalScrollIndicatorInsets = layout.scrollViewIndicatorInsets
        }
        else {
            adjustableScrollView.scrollIndicatorInsets = layout.scrollViewIndicatorInsets
        }
    }

    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            safeAreaInsets: safeAreaInsets,
            defaultInsets: adjustingDefaultInsets,
            keyboardHeight: keyboardHeight)
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let safeAreaInsets: UIEdgeInsets
    let defaultInsets: UIEdgeInsets
    let keyboardHeight: CGFloat

    var scrollViewContentInsets: UIEdgeInsets {
        let top = safeAreaInsets.top + defaultInsets.top
        let bottom = defaultInsets.bottom + keyboardHeight
        return UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
    }

    var scrollViewIndicatorInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight - safeAreaInsets.bottom, right: 0)
    }
}
