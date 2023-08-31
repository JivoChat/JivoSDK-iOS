//
//  JVSessionServer.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 22.03.2023.
//

import Foundation

/**
 Primary Jivo servers, by geographical region
 */
@objc(JVSessionServer)
public enum JVSessionServer: Int {
    case auto
    case asia
    case europe
    case russia
}
