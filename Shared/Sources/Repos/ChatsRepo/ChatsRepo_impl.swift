//
//  ChatsRepo.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 23.10.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation

final class ChatsRepo: IChatsRepo {
    private let databaseDriver: JVIDatabaseDriver
    
    init(databaseDriver: JVIDatabaseDriver) {
        self.databaseDriver = databaseDriver
    }
    
    func updateDraft(id: Int, currentText: String?) {
        let change = JVChatDraftChange(ID: id, draft: currentText)
        _ = databaseDriver.update(of: JVChat.self, with: change)
    }
}
