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
public enum JVSessionServer: String, CaseIterable {
    case auto
    case asia
    case europe
    case russia
}
