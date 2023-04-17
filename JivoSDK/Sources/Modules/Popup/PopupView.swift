//  
//  PopupView.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 30.11.2020.
//

import Foundation
import UIKit


final class PopupView: SdkModuleView<PopupViewUpdate, PopupViewEvent> {
    private lazy var popupView = PopupInformingContainer()
    
    init(engine: ISdkEngine?) {
        super.init()
        
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func handleMediator(update: PopupViewUpdate) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let layout = getLayout(size: view.bounds.size)
        popupView.frame = layout.popupViewFrame
    }
    
    func display(title: String?, icon: UIImage?, template: Bool, iconMode: UIView.ContentMode) {
        popupView.display(title: title, icon: icon, template: template, iconMode: iconMode)
    }
    
    private func setup() {
        view.addSubview(popupView)
        popupView.backgroundColor = .clear
        popupView.resignFirstResponder()
        popupView.completionHandler = { [weak self] in
            self?.dismiss(animated: true)
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewDidTap(_:)))
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func viewDidTap(_ sender: UIView) {
        dismiss(animated: true)
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
    
    var safeAreaFrame: CGRect {
        return bounds.inset(by: safeAreaInsets)
    }
    
    var popupViewFrame: CGRect {
        return bounds
    }
}
