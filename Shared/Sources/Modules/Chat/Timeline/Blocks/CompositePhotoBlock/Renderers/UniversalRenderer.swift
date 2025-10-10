//
//  UniversalRenderer.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 28.02.2022.
//  Copyright © 2022 jivosite.mobile. All rights reserved.
//

import Foundation
import UIKit

final class UniversalRenderer: UIImageView, Renderer {
    init() {
        super.init(frame: .zero)
        
        contentMode = .scaleAspectFill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(url: URL, completion: @escaping (URL?) -> Void) {
        jmLoadImage(with: url) { result in
            switch result {
            case .success: completion(url)
            case .failure: break
            }
        }
    }
    
    func configure(data: Data) {
        image = UIImage(data: data)
    }
    
    func configure(image: UIImage) {
        self.image = image
    }
    
    func pause() {
    }
    
    func resume() {
    }
    
    func reset() {
        image = nil
    }
}
