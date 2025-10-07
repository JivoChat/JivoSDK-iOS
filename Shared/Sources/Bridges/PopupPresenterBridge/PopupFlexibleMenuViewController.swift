//
//  PopupFlexibleMenuViewController.swift
//  App
//
//  Created by Yulia Popova on 11.09.2023.
//

import UIKit

final class PopupFlexibleMenuViewController: UITableViewController {
    private struct UIConstants {
        static let width: CGFloat = 290.0
        static let headerHeight: CGFloat = 8.0
        static let footerHeight: CGFloat = 8.0
    }
    
    var items = [PopupPresenterFlexibleMenuItem]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = JVDesign.colors.resolve(usage: .primaryBackground)
        tableView.alwaysBounceVertical = false
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PopupFlexibleMenuItemCell.self, forCellReuseIdentifier: PopupFlexibleMenuItemCell.reuseID)
        tableView.register(PopupFlexibleMenuTitleCell.self, forCellReuseIdentifier: PopupFlexibleMenuTitleCell.reuseID)
        
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.layoutIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame.size = CGSize(
            width: UIConstants.width,
            height: tableView.contentSize.height
        )
        
        preferredContentSize = tableView.frame.size
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentItem = items[indexPath.row]
        
        switch currentItem {
        case .title(let text):
            let cell = PopupFlexibleMenuTitleCell()
            cell.configure(title: text)
            return cell
        case .action(let title, let icon, let detail, let options, _):
            let cell = PopupFlexibleMenuItemCell()
            cell.configure(icon: icon, title: title, detail: detail, options: options)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView: UIView = .init(
            frame: .init(
                x: 0,
                y: 0,
                width: tableView.frame.width,
                height: UIConstants.headerHeight
            )
        )
        
        headerView.backgroundColor = JVDesign.colors.resolve(usage: .groupingBackground)
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UIConstants.headerHeight
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView: UIView = .init(
            frame: .init(
                x: 0,
                y: 0,
                width: tableView.frame.width,
                height: UIConstants.footerHeight
            )
        )
        
        footerView.backgroundColor = JVDesign.colors.resolve(usage: .groupingBackground)
        
        return footerView
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let item = items[indexPath.row]
        if case .action(_, _, _, _, let handler) = item { handler?() }
        
        dismiss(animated: true)
    }
}

extension PopupFlexibleMenuViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
