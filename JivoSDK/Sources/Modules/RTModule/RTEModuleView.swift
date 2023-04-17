//  
//  RTEModuleView.swift
//  App
//
//  Created by Stan Potemkin on 15.06.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation
import UIKit

class RTEModulePipelineViewNotifier<ViewIntent> {
    func notify(intent: ViewIntent) {}
}

protocol IRTEModulePipelineViewHandler: AnyObject {
    associatedtype PresenterUpdate
    func handlePresenter(update: PresenterUpdate)
}

class RTEModuleBaseViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
}

class RTEModuleViewStandalone<PresenterUpdate, ViewIntent>: RTEConfigBaseViewStandalone, IRTEModulePipelineViewHandler {
    let pipeline: RTEModulePipelineViewNotifier<ViewIntent>
    
    private var childrenModuleViews: [UUID: UIViewController]
    
    init(pipeline: RTEModulePipelineViewNotifier<ViewIntent>) {
        self.pipeline = pipeline
        
        childrenModuleViews = Dictionary()
        
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handlePresenter(update: PresenterUpdate) {
    }
    
    final func registerChild(uuid: UUID, child: UIViewController) {
        childrenModuleViews[uuid] = child
    }
    
    final func retrieveChild(uuid: UUID) -> UIViewController? {
        return childrenModuleViews[uuid]
    }
}

class RTEModuleBaseNavigationController: UINavigationController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
}

class RTEModuleViewNavigatable<PresenterUpdate, ViewIntent>: UINavigationController, IRTEModulePipelineViewHandler {
    let primaryView: RTEModuleViewStandalone<PresenterUpdate, ViewIntent>
    
    init(primaryView: RTEModuleViewStandalone<PresenterUpdate, ViewIntent>) {
        self.primaryView = primaryView
        
        super.init()
        
        viewControllers = [primaryView]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handlePresenter(update: PresenterUpdate) {
        primaryView.handlePresenter(update: update)
    }
}
