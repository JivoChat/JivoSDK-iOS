//  
//  OptionsMediator.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 03.12.2020.
//

import Foundation
import CollectionAndTableViewCompatible
import JMCodingKit

final class OptionsMediator: SdkModuleMediator<OptionsStorage, OptionsCoreUpdate, OptionsViewUpdate, OptionsViewEvent, OptionsCoreRequest, OptionsJointOutput> {
    
    private var tableViewDataSource: OptionsTableViewDataSource?
    private var tableViewData: [TableViewCompatible] = []
    
    override init(storage: OptionsStorage) {
        super.init(storage: storage)
    }
    
    override func handleCore(update: OptionsCoreUpdate) {
        switch update {
        case let .optionsUpdated(options):
            handleOptionsUpdated(options)
            
        case .optionDidTap(let option):
            notifyJoint(output: .optionDidTap(option.type))
        }
    }
    
    override func handleView(event: OptionsViewEvent) {
        switch event {
        case let .tableViewPrepared(tableView):
            handleTableViewPrepared(tableView)
            
        case .cellDidTap(let indexPath):
            guard let model = tableViewData[indexPath.row] as? OptionsCellModel else { return }
            notifyJoint(output: .optionDidTap(model.type))
        }
    }
    
    private func handleTableViewPrepared(_ tableView: UITableView) {
        tableViewDataSource = OptionsTableViewDataSource(data: tableViewData, tableView: tableView)
    }
    
    private func handleOptionsUpdated(_ options: OrderedMap<ContextMenuOptionType, ContextMenuOption>) {
        let tableViewData = options.map { option in
            return OptionsCellModel(
                type: option.key,
                icon: option.value.icon,
                title: option.value.title
            )
        }
        
        self.tableViewData = tableViewData
        tableViewDataSource?.data = tableViewData
        
        notifyView(update: .tableViewDataUpdated(tableViewData))
    }
}
