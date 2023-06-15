//  
//  PopupMediator.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 30.11.2020.
//

import Foundation

final class PopupMediator: SdkModuleMediator<PopupStorage, PopupCoreUpdate, PopupViewUpdate, PopupViewEvent, PopupCoreRequest, PopupJointOutput> {
    override init(storage: PopupStorage) {
        super.init(storage: storage)
    }
    
    override func handleCore(update: PopupCoreUpdate) {
    }
    
    override func handleView(event: PopupViewEvent) {
    }
}
