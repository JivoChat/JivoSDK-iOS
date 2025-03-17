//
//  OptionsTableViewDataSource.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 03.12.2020.
//

import Foundation
import UIKit
import CollectionAndTableViewCompatible

class OptionsTableViewDataSource: TableViewDataSource {
    
    // MARK: Public properties
        
    var data: [TableViewCompatible] {
        didSet {
            prepareData()
            tableView.reloadData()
        }
    }
    
    // MARK: Init
    
    init(data: [TableViewCompatible] = [], tableView: UITableView) {
        tableView.register(OptionsTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(OptionsTableViewCell.self))
        self.data = data
        super.init(tableView: tableView)
        prepareData()
    }
    
    // MARK: Public methods
    
    func prepareData() {
        let section = TableViewSection(sortOrder: 0, items: data)
        sections = [section]
    }
}
