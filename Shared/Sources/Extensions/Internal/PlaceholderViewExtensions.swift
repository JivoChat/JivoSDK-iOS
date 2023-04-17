//
//  PlaceholderViewExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 27/06/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit
#if canImport(JivoFoundation)
import JivoFoundation
#endif

enum PlaceholderBoxState {
    case regular
    case notFound
}

enum PlaceholderBoxActivity {
    case freshLoading(requestingMore: Bool)
    case standalone(canRequestMore: Bool)
}

final class PlaceholderViewBuildingContext {
    var items = [PlaceholderItem]()
    
    func appendRegular(_ content: PlaceholderItemContent) {
        items.append(
            PlaceholderItem(
                content: content,
                gap: .auto)
        )
    }
    
    func appendScaled(_ content: PlaceholderItemContent) {
        items.append(
            PlaceholderItem(
                content: content,
                gap: .auto,
                scale: jv_convert(JVDesign.environment.screenSize()) { value in
                    switch value {
                    case .small: return 0.25
                    case .standard: return 0.5
                    case .large: return 0.75
                    case .extraLarge: return 1.0
                    }
                })
        )
    }
    
    func appendTop(_ content: PlaceholderItemContent) {
        items.append(
            PlaceholderItem(
                content: content,
                gap: .shortBottom)
        )
    }
    
    func appendBottom(_ content: PlaceholderItemContent) {
        items.append(
            PlaceholderItem(
                content: content,
                gap: .shortTop)
        )
    }
}

extension PlaceholderViewController {
    func configureBox(builder: (PlaceholderViewBuildingContext) -> Void) {
        let context = PlaceholderViewBuildingContext()
        builder(context)
        placeholderItems = context.items
    }
}
