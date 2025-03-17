//
//  OptionsCellModel.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 03.12.2020.
//

import Foundation
import UIKit
import CollectionAndTableViewCompatible

class OptionsCellModel: TableViewCompatible {
    
    // MARK: Public properties
    
    let type: ContextMenuOptionType
    let icon: UIImage?
    let title: String
    let tapHandler: (() -> Void)?

    // MARK: TableViewCompatible
    
    var reuseIdentifier: String {
        return NSStringFromClass(OptionsTableViewCell.self)
    }
    var selected: Bool = false
    var editable: Bool = false
    var movable: Bool = false
    
    // MARK: Init
    
    init(type: ContextMenuOptionType, icon: UIImage?, title: String, tapHandler: (() -> Void)? = nil) {
        self.type = type
        self.icon = icon
        self.title = title
        self.tapHandler = tapHandler
    }
    
    func cellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseIdentifier, for: indexPath) as! OptionsTableViewCell
        cell.configure(withModel: self)
        
        return cell
    }
}
