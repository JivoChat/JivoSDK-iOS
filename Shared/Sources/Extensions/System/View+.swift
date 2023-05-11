//
//  ArrayExtensions.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 28/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

@available(iOS 13.0, *)
extension View {
    func jv_build() -> UIView {
        return UIHostingController(rootView: self).view ?? UIView()
    }
}
