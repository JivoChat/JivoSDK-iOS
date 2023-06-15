//
//  OptionsTableViewDelegate.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 06.12.2020.
//

import UIKit

enum TableViewDelegateAction {
    
    case rowSelection(atIndexPath: IndexPath)
}

class OptionsTableViewDelegate: NSObject, UITableViewDelegate {
    
    var actionHandler: ((TableViewDelegateAction) -> Void)?
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        actionHandler?(.rowSelection(atIndexPath: indexPath))
    }
}
