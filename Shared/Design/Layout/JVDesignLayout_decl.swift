//
//  JVDesignLayout.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 11.03.2023.
//

import Foundation

protocol JVIDesignLayout {
    var sideMargin: CGFloat { get }
    var controlMargin: CGFloat { get }
    var controlBigRadius: CGFloat { get }
    var controlSmallRadius: CGFloat { get }
    var alertRadius: CGFloat { get }
    var defaultMediaRatio: CGFloat { get }
}
