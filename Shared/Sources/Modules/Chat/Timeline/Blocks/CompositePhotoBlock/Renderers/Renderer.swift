//
//  Renderer.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 28.02.2022.
//  Copyright © 2022 jivosite.mobile. All rights reserved.
//

import Foundation
import UIKit

protocol Renderer: AnyObject {
    init()
    func pause()
    func resume()
    func reset()
}
