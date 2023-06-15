//  
//  PopupJoint.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 30.11.2020.
//

import Foundation

final class PopupJoint: SdkModuleJoint<PopupJointInput, PopupJointOutput> {
    private let engine: ISdkEngine
    
    init(engine: ISdkEngine) {
        self.engine = engine
    }
}
