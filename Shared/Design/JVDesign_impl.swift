//
//  JVDesign.swift
//  App
//
//  Created by Stan Potemkin on 16.01.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JMRepicKit

final class JVDesign: JVIDesign {
    public static let environment: JVIDesignEnvironment = JVDesignEnvironment()
    public static let colors: JVIDesignColors = JVDesignColors(environment: environment)
    public static let fonts: JVIDesignFonts = JVDesignFonts(environment: environment)
    public static let icons: JVIDesignIcons = JVDesignIcons(environment: environment)
    public static let layout: JVIDesignLayout = JVDesignLayout(environment: environment)

    public static func attachTo(application: UIApplication, window: UIWindow) {
        environment.grabFrom(application: application, window: window)
    }
}

class JVDesignEnvironmental {
    let environment: JVIDesignEnvironment
    
    init(environment: JVIDesignEnvironment) {
        self.environment = environment
    }
}
