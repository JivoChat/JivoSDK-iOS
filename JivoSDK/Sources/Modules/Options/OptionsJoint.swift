//  
//  OptionsJoint.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 03.12.2020.
//

import Foundation


final class OptionsJoint: SdkModuleJoint<OptionsJointInput, OptionsJointOutput> {
    private let engine: ISdkEngine
    private let presentingView: UIViewController
    
    init(engine: ISdkEngine, presentingView: UIViewController) {
        self.engine = engine
        self.presentingView = presentingView
    }
    
    override func handleMediator(event: OptionsJointOutput) {
        switch event {
        case .optionDidTap(let option):
            broadcast(.optionDidTap(option))
        }
    }
    
    func input(_ input: OptionsJointInput) {
        switch input {
        case .optionsToPresent(let options):
            notifyCore(request: .optionsToPresent(options))
        }
    }
}
