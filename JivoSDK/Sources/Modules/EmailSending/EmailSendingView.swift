//  
//  EmailSendingView.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 25.08.2021.
//

import Foundation
import UIKit
import MessageUI

final class EmailSendingView: SdkModuleView<EmailSendingViewUpdate, EmailSendingViewEvent> {
    private lazy var mailComposeViewController = MFMailComposeViewController()
    
    init(engine: ISdkEngine?) {
        super.init()
        
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        mailComposeViewController.dismiss(animated: true)
    }
    
    override func handleMediator(update: EmailSendingViewUpdate) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
//        let layout = getLayout(size: view.bounds.size)
    }
    
    private func setUp() {
        mailComposeViewController.mailComposeDelegate = self
        
        addChild(mailComposeViewController)
        present(mailComposeViewController, animated: true)
    }
    
    private func getLayout(size: CGSize) -> Layout {
        Layout(
            bounds: CGRect(origin: .zero, size: size),
            safeAreaInsets: safeAreaInsets)
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let safeAreaInsets: UIEdgeInsets
}

extension EmailSendingView: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        mailComposeViewController.dismiss(animated: true)
    }
}
