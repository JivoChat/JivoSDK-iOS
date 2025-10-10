//
//  SidePanelView.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 04.12.2020.
//

import Foundation
import UIKit


class SidePanelView: UIView, SidePanel {

    // MARK: - Constants
    
    private let TABLE_VIEW_ROW_HEIGHT: CGFloat = 56
    
    // MARK: - Public properties
    
    private(set) lazy var tableView = UITableView()

    // MARK: - Private properties

    

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        commonInit()
    }

    private func commonInit() {
        addSubview(tableView)
        tableView.backgroundColor = JVDesign.colors.resolve(usage: .primaryBackground)
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.estimatedRowHeight = TABLE_VIEW_ROW_HEIGHT
        tableView.rowHeight = TABLE_VIEW_ROW_HEIGHT
    }

    // MARK: - Public methods

    

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        let layout = getLayout(size: bounds.size)

        tableView.frame = layout.tableViewFrame
    }

    private func getLayout(size: CGSize) -> Layout {
        Layout(
            bounds: CGRect(origin: .zero, size: size),
            safeAreaInsets: safeAreaInsets)
    }
}

fileprivate struct Layout {

    let bounds: CGRect
    let safeAreaInsets: UIEdgeInsets

    var safeAreaFrame: CGRect {
        return bounds.inset(by: safeAreaInsets)
    }

    var tableViewFrame: CGRect {
        return bounds
    }
}
