//  
//  OptionsView.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 03.12.2020.
//

import Foundation
import UIKit

import CollectionAndTableViewCompatible

final class OptionsView: SdkModuleView<OptionsViewUpdate, OptionsViewEvent> {
    
    private let presentingView: UIViewController
    
    private lazy var sidePanelView = SidePanelView()
    
    private let tableViewDelegate = OptionsTableViewDelegate()
    
    init(engine: ISdkEngine?, presentingView: UIViewController) {
        self.presentingView = presentingView
        
        super.init()
        
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func handleMediator(update: OptionsViewUpdate) {
        switch update {
        case .tableViewDataUpdated(let data):
            handleTableViewDataUpdated(data)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        let layout = self.getLayout(size: self.view.bounds.size)
        self.sidePanelView.frame = layout.sidePanelViewFrame
        self.sidePanelView.present()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
//        let layout = getLayout(size: view.bounds.size)
    }
    
    private func handleTableViewDataUpdated(_ data: [TableViewCompatible]) {
        
    }
    
    private func setup() {
        // - sidePanelView
        view.addSubview(sidePanelView)
        // sidePanelView.present() – is in viewWillAppear(_:) method because of internal animation.
        
        notifyMediator(event: .tableViewPrepared(sidePanelView.tableView))
        
        // - tableViewDelegate
        tableViewDelegate.actionHandler = { [weak self] action in
            switch action {
            case .rowSelection(let indexPath):
                self?.notifyMediator(event: .cellDidTap(atIndexPath: indexPath))
                self?.dismiss()
            }
        }
        
        self.sidePanelView.tableView.delegate = self.tableViewDelegate
        
        // - tapGestureRecognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewDidTap(_:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
    }
    
    @objc private func viewDidTap(_ sender: UIView) {
        dismiss()
    }
    
    private func dismiss() {
        sidePanelView.dismiss() { [weak self] in
            self?.dismiss(animated: false)
        }
    }
    
    private func getLayout(size: CGSize) -> Layout {
        Layout(
            bounds: view.bounds,
            safeAreaInsets: safeAreaInsets,
            tableView: sidePanelView.tableView,
            presentingView: presentingView
        )
    }
}

fileprivate struct Layout {
    
    let bounds: CGRect
    let safeAreaInsets: UIEdgeInsets
    let tableView: UITableView
    let presentingView: UIViewController
    
    var safeAreaFrame: CGRect {
        return bounds.inset(by: safeAreaInsets)
    }
    
    // It's wrong to set the sidePanelView's frame in viewDidLayoutSubviews() method. If you'll do this, internal sidePanelView's animation won't work properly.
    var sidePanelViewFrame: CGRect {
        let bottomInset = presentingView.safeAreaInsets.bottom
        let numberOfRows = CGFloat((tableView.dataSource?.tableView(tableView, numberOfRowsInSection: 0) ?? 0))
        let height = (56 * numberOfRows) + bottomInset
        return CGRect(origin: CGPoint(x: .zero, y: bounds.maxY), size: CGSize(width: safeAreaFrame.width, height: height))
    }
}
