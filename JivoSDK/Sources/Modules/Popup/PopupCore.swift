//  
//  PopupCore.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 30.11.2020.
//

import Foundation

final class PopupCore: SdkModuleCore<PopupStorage, PopupCoreUpdate, PopupCoreRequest, PopupJointInput> {
    init() {
        let storage = PopupStorage()
        
        super.init(storage: storage)
    }
    
    override func run() {
    }
    
    override func handleMediator(request: PopupCoreRequest) {
    }
}
