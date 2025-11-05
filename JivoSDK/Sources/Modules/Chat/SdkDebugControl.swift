//
//  SdkDebugControl.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 31.10.2025.
//

import Foundation
import UIKit

final class SdkDebugControl : UILabel {
    init() {
        super.init(frame: .zero)
        
        text = "ver " + Bundle(for: Jivo.self).jv_formatVersion(.marketingShort)    
        font = UIFont.systemFont(ofSize: 14)
        textAlignment = .center
        textColor = JVDesign.colors.resolve(usage: .unnoticeableForeground)
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
