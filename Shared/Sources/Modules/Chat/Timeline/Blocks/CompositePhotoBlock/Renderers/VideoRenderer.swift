//
//  VideoRenderer.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 28.02.2022.
//  Copyright © 2022 jivosite.mobile. All rights reserved.
//

import UIKit
import JivoFoundation
import AVFoundation

final class VideoRenderer: UIView, Renderer {
    private let playImageUnderlay = UIView()
    private let playImage = UIImageView()
    
    private var activeVideoLayer: AVPlayerLayer?
    
    init() {
        super.init(frame: .zero)
        
        playImageUnderlay.backgroundColor = JVDesign.colors.resolve(usage: .oppositeBackground).jv_withAlpha(0.5)
        playImageUnderlay.layer.masksToBounds = true
        playImageUnderlay.layer.zPosition = 1
        addSubview(playImageUnderlay)

        playImage.image = UIImage(named: "player_resume", in: Bundle(for: JVDesign.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        playImage.tintColor = JVDesign.colors.resolve(usage: .oppositeForeground)
        playImage.layer.zPosition = 1
        addSubview(playImage)
        
        contentMode = .scaleAspectFill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let controlSide = bounds.width * 0.35
        activeVideoLayer?.frame = bounds
        playImageUnderlay.frame = CGRect(x: (bounds.width - controlSide) * 0.5, y: (bounds.height - controlSide) * 0.5, width: controlSide, height: controlSide)
        playImageUnderlay.layer.cornerRadius = controlSide * 0.5
        playImage.frame = playImageUnderlay.frame.insetBy(dx: controlSide * 0.15, dy: controlSide * 0.15)
    }
    
    func configure(url: URL, completion: @escaping (URL?) -> Void) {
        let player = AVPlayer(url: url)
        
        let videoLayer = AVPlayerLayer(player: player)
        videoLayer.videoGravity = .resizeAspectFill
        
        activeVideoLayer?.removeFromSuperlayer()
        activeVideoLayer = videoLayer
        layer.addSublayer(videoLayer)
    }
    
    func configure(data: Data) {
    }
    
    func pause() {
    }
    
    func resume() {
    }
    
    func reset() {
        activeVideoLayer?.removeFromSuperlayer()
    }
}
