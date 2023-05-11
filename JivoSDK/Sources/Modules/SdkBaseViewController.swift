//
//  BaseViewController.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 21.09.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation
import UIKit
import JMSidePanelKit


protocol SdkBaseViewControllerDelegate: AnyObject {
    func contentTopMargin() -> CGFloat
    func shouldActivateInteractiveGesture() -> Bool
}

class SdkBaseViewController: UIViewController, JMSidePanelView, SdkBaseViewControllerDelegate {
    enum ExecutionReason {
        case appear
        case layout
    }

    var jumpBackHandler: (() -> Bool)?

    private let onceAppearedToken = UUID()
    private let onceLayoutToken = UUID()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        extendedLayoutIncludesOpaqueBars = false
        
        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "",
            style: .plain,
            target: nil,
            action: nil
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func replaceBackButton(action: Selector) {
        let backItem = UIBarButtonItem(
            image: JVDesign.icons.find(preset: .back),
            style: .plain,
            target: self,
            action: action
        )
        
        backItem.accessibilityIdentifier = Accessibility.Common.backButton
        
        navigationItem.leftBarButtonItem = backItem
    }

    func removeBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: nil,
            style: .plain,
            target: nil,
            action: nil
        )
    }

    func executeOnce(reason: ExecutionReason, block: () -> Void) {
        switch reason {
        case .appear: DispatchQueue.jv_once(token: onceAppearedToken, block: block)
        case .layout: DispatchQueue.jv_once(token: onceLayoutToken, block: block)
        }
    }

    func contentTopMargin() -> CGFloat {
        return safeAreaInsets.top
    }
    
    func overrideUsingStatusLine() -> Bool {
        return true
    }
    
    func shouldActivateInteractiveGesture() -> Bool {
        return true
    }

    func jumpBack(animated: Bool) {
        if jumpBackHandler?() == true {
            return
        }

        navigationController?.popViewController(animated: animated)
    }
    
    func applyExtraInsets(_ insets: UIEdgeInsets) {
    }
    
    func preferredSize(for width: CGFloat) -> CGSize {
        return .zero
    }

    override func viewWillAppear(_ animated: Bool) {
        journal { [brief = String(describing: self)] in "View will appear: \(brief)"}
        
//        satellite?.telemetryService.trackViewAppear(
//            details: selfMessage)
        
        super.viewWillAppear(animated)
//        satellite?.trackerService.willAppear(self)
    }
    
    @objc func handleJumpBack() {
        jumpBack(animated: true)
    }
}
