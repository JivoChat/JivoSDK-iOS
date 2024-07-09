//  
//  OptionsStorage.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 03.12.2020.
//

import Foundation
import JMCodingKit

final class OptionsStorage: IOptionsStorage {
    
    init() {}
    
    func obtainAllOptions() -> OrderedMap<ContextMenuOptionType, ContextMenuOption> {
        let options: OrderedMap<ContextMenuOptionType, ContextMenuOption> = [
            .copy: ContextMenuOption(
                type: .copy,
                icon: JVDesign.icons.find(asset: .context_copy, rendering: .original),
                title: loc["JV_ChatTimeline_MessageAction_Copy", "options_copy"]
            ),
            .resendMessage: ContextMenuOption(
                type: .resendMessage,
                icon: JVDesign.icons.find(asset: .context_repeat, rendering: .original),
                title: loc["JV_ChatTimeline_MessageAction_Resend", "options_resend"]
            )
        ]
        
        return options
    }
}
