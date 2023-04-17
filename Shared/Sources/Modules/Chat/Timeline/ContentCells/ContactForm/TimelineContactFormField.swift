//
//  TimelineContactFormField.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 13.01.2023.
//

import Foundation
import UIKit

struct TimelineContactFormField {
    let id: String
    let placeholder: String
    let value: String?
    let keyboardType: UIKeyboardType
    let interactivity: Interactivity
}

extension TimelineContactFormField {
    enum Interactivity {
        case enabled
        case disabled
    }
}
