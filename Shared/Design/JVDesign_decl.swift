//
//  JVDesignDecl.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 12.03.2023.
//

import Foundation

protocol JVIDesign {
    static var environment: JVIDesignEnvironment { get }
    static var layout: JVIDesignLayout { get }
    static var colors: JVIDesignColors { get }
    static var fonts: JVIDesignFonts { get }
    static var icons: JVIDesignIcons { get }
    static func attachTo(application: UIApplication, window: UIWindow)
}
