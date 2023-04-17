//  
//  RTEModule.swift
//  App
//
//  Created by Stan Potemkin on 15.06.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation
import UIKit

struct RTEModule<
    PresenterUpdate,
    ViewIntent,
    Joint,
    View: IRTEModulePipelineViewHandler
> where View.PresenterUpdate == PresenterUpdate {
    static var navigator: Any { type(of: Joint.self) }
    let view: View
    let joint: Joint
}
