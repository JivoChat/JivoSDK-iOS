//
//  BaseViewController.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMSidePanelKit

protocol BaseViewControllerSatellite {
    var keyboardListenerBridge: IKeyboardListenerBridge { get }
    func viewWillAppear(viewController: UIViewController)
}

protocol BaseViewControllerDelegate: AnyObject {
    func contentTopMargin() -> CGFloat
    func shouldActivateInteractiveGesture() -> Bool
}

class BaseViewController<Satellite: BaseViewControllerSatellite>: UIViewController, JMSidePanelView, BaseViewControllerDelegate {
    enum ExecutionReason {
        case appear
        case layout
    }

//    let satellite: AppEngineUIC?

    let satellite: Satellite?
    
    var jumpBackHandler: (() -> Bool)?

    private let onceAppearedToken = UUID()
    private let onceLayoutToken = UUID()
    
    init(satellite: Satellite?) {
        self.satellite = satellite
        
        super.init(nibName: nil, bundle: nil)
        
        extendedLayoutIncludesOpaqueBars = false
        
        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: String(),
            style: .plain,
            target: nil,
            action: nil
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = JVDesign.colors.resolve(usage: .primaryBackground)
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
        super.viewWillAppear(animated)
        satellite?.viewWillAppear(viewController: self)
    }
    
    @objc func handleJumpBack() {
        jumpBack(animated: true)
    }
}
