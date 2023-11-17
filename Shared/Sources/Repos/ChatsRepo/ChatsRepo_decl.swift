//
//  ChatsRepoDecl.swift
//  App
//
//  Created by Stan Potemkin on 09.03.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation

protocol IChatsRepo: AnyObject {
    func updateDraft(id: Int, currentText: String?)
}
