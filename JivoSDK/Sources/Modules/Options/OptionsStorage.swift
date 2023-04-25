//  
//  OptionsStorage.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 03.12.2020.
//

import Foundation
import JivoFoundation
import JMCodingKit

final class OptionsStorage: IOptionsStorage {
    
    init() {}
    
    func obtainAllOptions() -> OrderedMap<ContextMenuOptionType, ContextMenuOption> {
        let options: OrderedMap<ContextMenuOptionType, ContextMenuOption> = [
            .copy: ContextMenuOption(
                type: .copy,
                icon: JVDesign.icons.find(asset: .context_copy, rendering: .original),
                title: loc["options_copy"]
            ),
            .resendMessage: ContextMenuOption(
                type: .resendMessage,
                icon: JVDesign.icons.find(asset: .context_repeat, rendering: .original),
                title: loc["options_resend"]
            )
        ]
        
        return options
    }
}
