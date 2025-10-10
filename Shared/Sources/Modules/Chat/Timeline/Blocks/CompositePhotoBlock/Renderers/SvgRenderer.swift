//
//  SvgRenderer.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 10.12.2024.
//

import Foundation
import UIKit

#if canImport(SVGKit)
import SVGKit
#endif

final class SvgRenderer: UIImageView, Renderer {
    init() {
        super.init(frame: .zero)
        
        contentMode = .scaleAspectFill
        isUserInteractionEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(url: URL) {
        #if canImport(SVGKit)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let generator = SVGKImage(contentsOf: url)
            DispatchQueue.main.async { [weak self] in
                self?.image = generator?.uiImage
            }
        }
        #endif
    }
    
    func pause() {
    }
    
    func resume() {
    }
    
    func reset() {
        image = nil
    }
}
