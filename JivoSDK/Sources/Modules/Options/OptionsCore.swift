//  
//  OptionsCore.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 03.12.2020.
//

import Foundation
import JMCodingKit

enum ContextMenuOptionType {
    
    case copy
    case resendMessage
}

struct ContextMenuOption {
    
    let type: ContextMenuOptionType
    let icon: UIImage?
    let title: String
}

final class OptionsCore: SdkModuleCore<OptionsStorage, OptionsCoreUpdate, OptionsCoreRequest, OptionsJointInput> {
    
    private var options = OrderedMap<ContextMenuOptionType, ContextMenuOption>()
    
    init() {
        let storage = OptionsStorage()
        
        super.init(storage: storage)
    }
    
    override func run() {
        prepareOptions()
    }
    
    override func handleMediator(request: OptionsCoreRequest) {
    }
    
    override func handleJoint(input: OptionsJointInput) {
        switch input {
        case let .optionsToPresent(options):
            handleOptionsToPresent(options)
        }
    }
    
    private func handleOptionsToPresent(_ options: [ContextMenuOptionType]) {
        prepareOptions(filteredBy: options)
    }
    
    private func prepareOptions(filteredBy optionTypesToPrepare: [ContextMenuOptionType] = []) {
        let allOptions = storage.obtainAllOptions()
        
        optionTypesToPrepare.forEach {
            self.options[$0] = allOptions[$0]
        }
        
        notifyMediator(update: .optionsUpdated(options))
    }
}
