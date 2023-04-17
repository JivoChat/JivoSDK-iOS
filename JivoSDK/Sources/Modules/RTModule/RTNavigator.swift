//
//  RTNavigator.swift
//  App
//
//  Created by Stan Potemkin on 16.06.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import BABFrameObservingInputAccessoryView

class RTNavigatorDestination<Module> {
    typealias Reducer<Output> = (Output) -> ModuleNavigationFinish
    typealias Builder = (RTEConfigTrunk, IRTNavigator, @escaping (ModuleNavigationFinish) -> Void) -> (Module, UIViewController)
    
    let builder: Builder
    init(builder: @escaping Builder) {
        self.builder = builder
    }
}

protocol IRTNavigator: AnyObject {
    var engine: RTEConfigTrunk { get }
    func add(handler: RTEModuleJointNavigationHandler)
    func remove(handler: RTEModuleJointNavigationHandler)
    
    @discardableResult
    func build<Module>(destinationProvider: () -> RTNavigatorDestination<Module>) -> (module: Module, view: UIViewController)
    
    @discardableResult
    func replace<Module>(inside parent: ModuleNavigationParent, destinationProvider: () -> RTNavigatorDestination<Module>) -> Module
    
    @discardableResult
    func embed<Module>(within parent: ModuleNavigationParent, transition: RootTransitionMode, destinationProvider: () -> RTNavigatorDestination<Module>) -> Module
    
    @discardableResult
    func push<Module>(into parent: ModuleNavigationParent, animate: Bool, destinationProvider: () -> RTNavigatorDestination<Module>) -> Module
    
    @discardableResult
    func present<Module>(over parent: ModuleNavigationParent, animate: Bool, destinationProvider: () -> RTNavigatorDestination<Module>) -> Module
}

final class RTNavigator: IRTNavigator {
    let engine: RTEConfigTrunk
    
    private let navigationChain = NSHashTable<RTEModuleJointNavigationHandler>.weakObjects()
    
    init(engine: RTEConfigTrunk) {
        self.engine = engine
    }
    
    func add(handler: RTEModuleJointNavigationHandler) {
        navigationChain.add(handler)
    }
    
    func remove(handler: RTEModuleJointNavigationHandler) {
        navigationChain.remove(handler)
    }
    
    func build<Module>(destinationProvider: () -> RTNavigatorDestination<Module>) -> (module: Module, view: UIViewController) {
        let (module, view) = destinationProvider().builder(engine, self) { finish in
        }
        
        return (module, view)
    }
    
    func replace<Module>(inside parent: ModuleNavigationParent, destinationProvider: () -> RTNavigatorDestination<Module>) -> Module {
        guard let anchor = retrieveAnchor(parent: parent),
              let container = anchor as? UINavigationController
        else {
            preconditionFailure()
        }
        
        let (module, view) = destinationProvider().builder(engine, self) { finish in
        }
        
        container.viewControllers = [view]
        
        return module
    }
    
    func embed<Module>(within parent: ModuleNavigationParent, transition: RootTransitionMode, destinationProvider: () -> RTNavigatorDestination<Module>) -> Module {
        guard let anchor = retrieveAnchor(parent: parent)
        else {
            preconditionFailure()
        }
        
        let (module, view) = destinationProvider().builder(engine, self) { finish in
        }
        
        anchor.setActiveViewController(view, transition: transition)
        
        return module
    }
    
    func push<Module>(into parent: ModuleNavigationParent, animate: Bool, destinationProvider: () -> RTNavigatorDestination<Module>) -> Module {
        guard let anchor = retrieveAnchor(parent: parent)
        else {
            preconditionFailure()
        }
        
        let container: UINavigationController? = {
            if let navigationController = anchor as? UINavigationController {
                return navigationController
            }
            
            var iterator: UIViewController? = anchor
            while (iterator != nil) {
                if let navigationController = iterator?.navigationController {
                    return navigationController
                }
                else {
                    iterator = iterator?.parent
                }
            }
            
            return nil
        }()
        
        let (module, view) = destinationProvider().builder(engine, self) { [weak container] finish in
            switch finish {
            case .keep:
                break
            case .close(let animate):
                container?.popViewController(animated: animate)
            }
        }
        
        container?.pushViewController(view, animated: animate)
        
        return module
    }
    
    func present<Module>(over parent: ModuleNavigationParent, animate: Bool, destinationProvider: () -> RTNavigatorDestination<Module>) -> Module {
        guard let anchor = retrieveAnchor(parent: parent)
        else {
            preconditionFailure()
        }
        
        let (module, view) = destinationProvider().builder(engine, self) { [weak anchor] finish in
            switch finish {
            case .keep:
                break
            case .close(let animate):
                anchor?.dismiss(animated: animate)
            }
        }
        
        switch parent {
        default:
            anchor.present(view, animated: animate)
        }
        
        return module
    }
    
    private func retrieveAnchor(parent: ModuleNavigationParent) -> UIViewController? {
        switch parent {
        case .root:
            let root = navigationChain.allObjects.first
            return root?.view
            
        case .native(let viewController):
            return viewController
            
        case .here(let handler):
            return handler.view
            
        case .specific(let joint):
            for element in navigationChain.objectEnumerator() {
                guard let element = element as? RTEModuleJointNavigationHandler,
                      element.isIdenticalTo(joint: joint)
                else {
                    continue
                }
                
                return element.view
            }
            
        case .responsible(let kind):
            for element in navigationChain.objectEnumerator() {
                guard let element = element as? RTEModuleJointNavigationHandler,
                      element.isResponsibleFor(navigationKind: kind)
                else {
                    continue
                }
                
                return element.view
            }
        }
        
        return nil
    }
}

final class MockViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let textField = UITextField()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bab = BABFrameObservingInputAccessoryView()
        bab.frame.size.height = 0
        
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        
        textField.placeholder = "UITextField"
        textField.textAlignment = .center
        textField.inputAccessoryView = bab
        scrollView.addSubview(textField)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        scrollView.contentSize = view.bounds.size
        textField.frame = CGRect(x: 0, y: view.bounds.height - 300, width: view.bounds.width, height: 40)
    }
}

