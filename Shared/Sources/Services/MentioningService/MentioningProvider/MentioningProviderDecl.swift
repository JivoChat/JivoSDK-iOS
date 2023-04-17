//
//  MentioningProviderDecl.swift
//  App
//
//  Created by Stan Potemkin on 09.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

protocol IMentioningProvider {
    func retrieveAgentName(forID ID: Int, generateDefault: Bool) -> String?
}
