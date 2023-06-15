//  
//  OptionsAssembly.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 03.12.2020.
//

import UIKit
import CollectionAndTableViewCompatible
import JMCodingKit

protocol IOptionsStorage {
}

enum OptionsCoreUpdate {
    
    case optionsUpdated(_ options: OrderedMap<ContextMenuOptionType, ContextMenuOption>)
    case optionDidTap(_ option: ContextMenuOption)
}

enum OptionsCoreRequest {
    
    case cellDidTap(model: TableViewCompatible)
}

enum OptionsViewUpdate {
    
    case tableViewDataUpdated(_ data: [TableViewCompatible])
}

enum OptionsViewEvent {
    
    case tableViewPrepared(_ tableView: UITableView)
    case cellDidTap(atIndexPath: IndexPath)
}

enum OptionsJointInput {
    
    case optionsToPresent(_ options: [ContextMenuOptionType])
}

enum OptionsJointOutput {
    
    case optionDidTap(_ option: ContextMenuOptionType)
}

func OptionsAssembly(engine: ISdkEngine, presentingView: UIViewController) -> SdkModule<OptionsView, OptionsJoint> {
    return SdkModuleAssembly(
        coreBuilder: {
            OptionsCore()
        },
        mediatorBuilder: { storage in
            OptionsMediator(
                storage: storage)
        },
        viewBuilder: {
            OptionsView(engine: engine, presentingView: presentingView)
        },
        jointBuilder: {
            OptionsJoint(engine: engine, presentingView: presentingView)
        })
}
