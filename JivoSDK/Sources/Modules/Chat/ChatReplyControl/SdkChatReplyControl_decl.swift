//
//  SdkChatReplyControl-decl.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 30.03.2023.
//

import Foundation
import UIKit

extension SdkChatReplyControl {
    struct Update {
        let input: Input?
        let submit: Submit?
    }
    
    enum Output {
        case menuLongPress(_ button: UIButton)
    }
}

extension SdkChatReplyControl.Update {
    enum Input {
        case active(placeholder: String?, text: String?, menu: Menu?)
        case inactive(reason: String?)
    }
    
    enum Menu {
        case active
        case inactive
        case hidden
    }
    
    enum Submit: Equatable {
        case send
        case connecting
    }
    
    static func initial(placeholder: String) -> Self {
        return .init(
            input: .active(
                placeholder: placeholder,
                text: nil,
                menu: nil
            ),
            submit: .send
        )
    }
}
