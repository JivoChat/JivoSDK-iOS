//
//  JMTimelineCompositeAudioBlock.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import UIKit
import JMDesignKit
import JMTimelineKit
import AVFoundation

enum JMTimelineCompositeAudioType {
    case audio
    case voice
    case inputVoice
}

struct JMTimelineCompositeAudioStyle: JMTimelineStyle {
    let tintColor: UIColor
}

struct JMTimelineCompositeAudioStyleExtended: JMTimelineStyle {
    let backViewColor: UIColor
    let buttonTintColor: UIColor
    let buttonBorderColor: UIColor
    let buttonBackgroundColor: UIColor
    let minimumTrackColor: UIColor
    let maximumTrackColor: UIColor
    let durationLabelColor: UIColor
}

final class JMTimelineCompositeAudioBlock: JMTimelineBlock {
    private let backView = UIView()
    private let playButton = UIButton()
    private let pauseButton = UIButton()
    private let sliderControl = PlaybackSlider()
    private let durationLabel = UILabel()
    
    private var item: URL?
    private var duration: TimeInterval?
    private var sliderColor = UIColor.clear
    private var extendedStyle: JMTimelineCompositeAudioStyleExtended?
    private var waveFormView = UIImageView()
    
    private var type: JMTimelineCompositeAudioType
    
    init(type: JMTimelineCompositeAudioType) {
        
        self.type = type
        
        super.init()
        
        clipsToBounds = false
        
        addSubview(backView)
        
        switch type {
        case .audio:
            break
        case .voice:
            waveFormView.tintColor = JVDesign.colors.resolve(usage: .waveformColor)
        case .inputVoice:
            waveFormView.tintColor = JVDesign.colors.resolve(alias: .white)
        }
        
        addSubview(waveFormView)

        let resumeIcon = UIImage(named: "player_resume", in: Bundle(for: JVDesign.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        playButton.setImage(resumeIcon, for: .normal)
        playButton.setImage(resumeIcon, for: .highlighted)
        playButton.contentVerticalAlignment = .center
        playButton.contentHorizontalAlignment = .center
        playButton.addTarget(self, action: #selector(handlePlayButton), for: .touchUpInside)
        addSubview(playButton)
        
        let pauseIcon = UIImage(named: "player_pause", in: Bundle(for: JVDesign.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        pauseButton.setImage(pauseIcon, for: .normal)
        pauseButton.setImage(pauseIcon, for: .highlighted)
        pauseButton.contentVerticalAlignment = .center
        pauseButton.contentHorizontalAlignment = .center
        pauseButton.addTarget(self, action: #selector(handlePauseButton), for: .touchUpInside)
        addSubview(pauseButton)
        
        switch type {
        case .audio:
            sliderControl.inset = -0.5
        case .voice:
            sliderControl.inset = -25.0
        case .inputVoice:
            sliderControl.inset = -10.0
        }
        
        sliderControl.minimumValue = 0
        sliderControl.maximumValue = 1.0
        addSubview(sliderControl)
        
        durationLabel.lineBreakMode = .byClipping
        addSubview(durationLabel)
        
        adjustForCurrentStatus()
        
        sliderControl.beginHandler = { [weak self] progress in
            guard let `self` = self, let item = self.item, let interactor = self.interactor else {
                return false
            }
            
            interactor.registerTouchingView(view: self.sliderControl)
            
            switch interactor.mediaPlayingStatus(item: item) {
            case .playing, .paused:
                interactor.pauseMedia(item: item)
                interactor.seekMedia(item: item, position: progress)
                return true
                
            case .none, .loading, .failed:
                return false
            }
        }
        
        sliderControl.adjustHandler = { [weak self] progress in
            guard let `self` = self, let item = self.item, let interactor = self.interactor else {
                return false
            }
            
            switch interactor.mediaPlayingStatus(item: item) {
            case .playing, .paused:
                interactor.seekMedia(item: item, position: progress)
                if let duration = self.duration {
                    self.durationLabel.text = self.generateProgressCaption(
                        current: duration * Double(progress),
                        duration: duration)
                }
                return true
                
            case .none, .loading, .failed:
                return false
            }
        }
        
        sliderControl.endHandler = { [weak self] in
            guard let `self` = self, let item = self.item, let interactor = self.interactor else {
                return
            }
            
            interactor.unregisterTouchingView(view: self.sliderControl)
            interactor.resumeMedia(item: item)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        unsubscribe()
    }
    
    func configure(item: URL, duration: TimeInterval?, provider: JVChatTimelineProvider, interactor: JVChatTimelineInteractor, extendedStyle: JMTimelineCompositeAudioStyleExtended) {
        self.item = item
        self.duration = duration
        self.extendedStyle = extendedStyle
        
        linkTo(provider: provider, interactor: interactor)
        drawWaveformIfNeeded()
        updateDesignWithExtendedStyle()
        adjustForCurrentStatus()
    }
    
    func updateDesignWithExtendedStyle() {
        super.updateDesign()
        
//        let sliderImage = generateThumbImage(
//            size: JVDesign.fonts.scaled(CGSize(width: 15, height: 15), category: .title1),
//            category: .title1,
//            color: sliderColor.darkenBy(value: 0.3)
//        )
//
//        backView.backgroundColor = sliderColor.darkenBy(value: 0.15)
//        playButton.tintColor = JVDesign.colors.resolve(alias: .white)
//        pauseButton.tintColor = JVDesign.colors.resolve(alias: .white)
//        sliderControl.minimumTrackTintColor = sliderColor.darkenBy(value: 0.3)
//        sliderControl.maximumTrackTintColor = sliderColor.darkenBy(value: 0.15)
//        sliderControl.setThumbImage(sliderImage, for: .normal)
//        durationLabel.textColor = sliderColor.darkenBy(value: 0.3)

        guard let style = extendedStyle else { return }
        
        backView.backgroundColor = style.backViewColor
        
        playButton.tintColor = style.buttonTintColor
        playButton.layer.borderWidth = 1
        playButton.layer.borderColor = style.buttonBorderColor.cgColor
        playButton.backgroundColor = style.buttonBackgroundColor
        
        pauseButton.tintColor = style.buttonTintColor
        pauseButton.layer.borderWidth = 1
        pauseButton.layer.borderColor = style.buttonBorderColor.cgColor
        pauseButton.backgroundColor = style.buttonBackgroundColor
        
        let minimumTrackImage = UIImage(jv_color: style.minimumTrackColor)?.resizableImage(withCapInsets: .zero)
        sliderControl.setMinimumTrackImage(minimumTrackImage, for: .normal)
        
        let maximumTrackImage = UIImage(jv_color: style.maximumTrackColor)?.resizableImage(withCapInsets: .zero)
        sliderControl.setMaximumTrackImage(maximumTrackImage, for: .normal)
        
        durationLabel.textColor =  style.durationLabelColor
        
        sliderControl.setThumbImage(UIImage(), for: .normal)
        durationLabel.font = obtainDurationFont()
    }
    
    override func handleLongPressGesture(recognizer: UILongPressGestureRecognizer) -> Bool {
        return false
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        if let _ = item {
            let layout = getLayout(size: size, type: type)
            return layout.totalSize
        }
        else {
            return CGSize(width: size.width, height: 0)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size, type: type)
        backView.frame = layout.backFrame
        backView.layer.cornerRadius = type == .inputVoice ? layout.backCornerRadius : 0
        playButton.frame = layout.buttonFrame
        playButton.layer.cornerRadius = layout.buttonCornerRadius
        pauseButton.frame = layout.buttonFrame
        pauseButton.layer.cornerRadius = layout.buttonCornerRadius
        sliderControl.frame = layout.sliderControlFrame
        durationLabel.frame = layout.durationLabelFrame
        waveFormView.frame = layout.waveformFrame
        waveFormView.isHidden = type == .audio
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if let _ = window {
            subscribe()
        }
        else {
            unsubscribe()
        }
    }
    
    private func getLayout(size: CGSize, type: JMTimelineCompositeAudioType) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            durationLabel: durationLabel,
            type: type
        )
    }
    
    private func subscribe() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMediaPlayerState),
            name: Notification.Name.JMMediaPlayerState,
            object: nil
        )
        drawWaveformIfNeeded()
    }
    
    private func unsubscribe() {
        NotificationCenter.default.removeObserver(self)
        
        if let item = item {
            interactor?.stopMedia(item: item)
        }
    }
    
    private func extractWaveformAndDraw() {
        guard let item = item else { return }
        let asset = AVAsset(url: item)
        let audioTracks: [AVAssetTrack] = asset.tracks(withMediaType: AVMediaType.audio)
        if let track: AVAssetTrack = audioTracks.first {
            let width = Int(getLayout(size: bounds.size, type: .voice).sliderControlFrame.width)
            WaveformSamplesExtractor.shared.samples(
                audioTrack: track,
                desiredNumberOfSamples: width,
                onSuccess: { samples, _, _ in
                    let configuration = WaveformConfiguration(
                        size: self.waveFormView.bounds.size,
                        color: UIColor.white,
                        backgroundColor: UIColor.clear,
                        lineWidth: 4,
                        space: 2,
                        pickToPickAmplitude: 20.0
                    )
                    
                    self.waveFormView.image = WaveFormDrawer.shared.image(
                        samples: samples,
                        configuration: configuration)
                }, onFailure: { }
            )
        }
    }
    
    private func adjustForCurrentStatus() {
        isHidden = (item == nil)
        
        guard
            let item = item,
            let status = interactor?.mediaPlayingStatus(item: item)
        else {
            return
        }
        
        switch status {
        case .none:
            playButton.isHidden = false
            pauseButton.isHidden = true
            sliderControl.value = 0
            durationLabel.text = duration.flatMap { generateProgressCaption(current: 0, duration: $0) }
            
        case .loading:
            playButton.isHidden = true
            pauseButton.isHidden = false
            sliderControl.value = 0
            durationLabel.text = duration.flatMap { generateProgressCaption(current: 0, duration: $0) }
            
        case .failed:
            playButton.isHidden = false
            pauseButton.isHidden = true
            sliderControl.value = 0
            durationLabel.text = duration.flatMap { generateProgressCaption(current: 0, duration: $0) }
            
        case .playing(let current, let duration):
            playButton.isHidden = true
            pauseButton.isHidden = false
            sliderControl.value = Float(current / duration)
            durationLabel.text = generateProgressCaption(current: current, duration: duration)
            
        case .paused(let current, let duration):
            playButton.isHidden = false
            pauseButton.isHidden = true
            sliderControl.value = Float(current / duration)
            durationLabel.text = generateProgressCaption(current: current, duration: duration)
        }
        
        setNeedsLayout()
    }
    
    private func generateProgressCaption(current: TimeInterval, duration: TimeInterval) -> String {
        let currentCaption = provider?.formattedTimeForPlayback(current) ?? String()
        let durationCaption = provider?.formattedTimeForPlayback(duration) ?? String()
        return "\(currentCaption) / \(durationCaption)"
    }
    
    private func drawWaveformIfNeeded() {
        guard let item = item else { return }
        
        switch type {
        case .audio:
            break
        case .voice:
            provider?.requestWaveformPoints(from: item, completion: { [weak self] result in
                guard let `self` = self else { return }
                guard let result else { return }
                guard item == self.item else { return }
                
                switch result {
                case .value(let meta, let kind):
                    switch kind {
                    case .binary:
                        var bytes = [UInt8]()
                        if let data = NSData(contentsOf: meta.localUrl) {
                            var buffer = [UInt8](repeating: 0, count: data.length)
                            data.getBytes(&buffer, length: data.length)
                            bytes = buffer
                            let floatBytes = bytes.map { Float($0) }
                            
                            let configuration = WaveformConfiguration(
                                size: self.waveFormView.bounds.size,
                                color: JVDesign.colors.resolve(usage: .waveformColor),
                                backgroundColor: UIColor.clear,
                                lineWidth: 4,
                                space: 2,
                                pickToPickAmplitude: 20.0
                            )
                            
                            self.waveFormView.image = WaveFormDrawer.shared.image(
                                samples: floatBytes,
                                configuration: configuration
                            )
                        }
                    default:
                        break
                    }
                default:
                    break
                }
            })
        case .inputVoice:
            let asset = AVAsset(url: item)
            let audioTracks: [AVAssetTrack] = asset.tracks(withMediaType: AVMediaType.audio)
            if let track: AVAssetTrack = audioTracks.first {
                let width = Int(getLayout(size: bounds.size, type: .voice).sliderControlFrame.width)
                WaveformSamplesExtractor.shared.samples(
                    audioTrack: track,
                    desiredNumberOfSamples: width,
                    onSuccess: { samples, _, _ in
                        let configuration = WaveformConfiguration(
                            size: self.waveFormView.bounds.size,
                            color: UIColor.white,
                            backgroundColor: UIColor.clear,
                            lineWidth: 4,
                            space: 2,
                            pickToPickAmplitude: 20.0
                        )
                        
                        self.waveFormView.image = WaveFormDrawer.shared.image(
                            samples: samples,
                            configuration: configuration)
                    }, onFailure: { }
                )
            }
        }
    }
    
    @objc private func handlePlayButton() {
        if let item = item {
            interactor?.playMedia(item: item)
        }
        
        adjustForCurrentStatus()
    }
    
    @objc private func handlePauseButton() {
        if let item = item {
            interactor?.pauseMedia(item: item)
        }
        
        adjustForCurrentStatus()
    }
    
    @objc private func handleDownloadButton() {
    }
    
    @objc private func handleMediaPlayerState(_ notification: Notification) {
        adjustForCurrentStatus()
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let durationLabel: UILabel
    let type: JMTimelineCompositeAudioType
    
    var backFrame: CGRect {
        return CGRect(x: 5, y: 0, width: buttonSize.width, height: buttonSize.height)
    }
    
    var backCornerRadius: CGFloat {
        return backFrame.width * 0.5
    }
    
    var buttonFrame: CGRect {
        return backFrame
    }
    
    var buttonCornerRadius: CGFloat {
        return buttonFrame.width * 0.5
    }
    
    var sliderControlFrame: CGRect {
        let horizontalPadding = CGFloat(12)
        let leftX = backFrame.maxX + horizontalPadding
        
        switch type {
        case .audio, .voice:
            if durationLabel.jv_hasText {
                let width = bounds.width - leftX
                let height = CGFloat(15)
                let topY = buttonFrame.minY
                return CGRect(x: leftX,
                              y: topY,
                              width: width,
                              height: height
                )
            } else {
                let width = bounds.width - leftX - horizontalPadding
                let height = CGFloat(15)
                let topY = backFrame.midY - height + 2
                return CGRect(x: leftX,
                              y: topY,
                              width: width,
                              height: height
                )
            }
        case .inputVoice:
            let width = durationLabelFrame.minX - backFrame.maxX - horizontalPadding
            return CGRect(x: backFrame.maxX,
                          y: bounds.origin.y,
                          width: width,
                          height: bounds.height
            )
        }
    }
    
    var durationLabelFrame: CGRect {
        switch type {
        case .audio, .voice:
            let size = durationLabel.sizeThatFits(.zero)
            let topY = sliderControlFrame.maxY + 15
            
            if durationLabel.jv_hasText {
                let leftX = backFrame.maxX + 12.0
                return CGRect(x: leftX,
                              y: buttonFrame.maxY - size.height,
                              width: size.width,
                              height: size.height
                )
            }
            else {
                return CGRect(x: bounds.width, y: topY, width: 0, height: 0)
            }
        case .inputVoice:
            let label = UILabel()
            label.text = "0:00/0:00"
            label.font = label.font
            let size = label.sizeThatFits(.zero)
            let topY = backFrame.minY + (backFrame.height - size.height) * 0.5
            let paddingRight = 12.0
            if durationLabel.jv_hasText {
                return CGRect(
                    x: bounds.width - size.width - paddingRight,
                    y: topY,
                    width: size.width,
                    height: size.height
                )
            }
            else {
                return CGRect(x: bounds.width, y: topY, width: 0, height: 0)
            }
        }
    }
    
    var totalSize: CGSize {
        let height = max(buttonSize.height, durationLabelFrame.maxY)
        return CGSize(width: bounds.width, height: height)
    }
    
    var waveformFrame: CGRect {
        return CGRect(
            x: sliderControlFrame.minX,
            y: type == .voice ? -10.0 : 0.0,
            width: sliderControlFrame.width,
            height: bounds.height
        )
    }
    
    private var buttonSize: CGSize {
        let size = CGSize(width: 38, height: 38)
        return JVDesign.fonts.scaled(size, category: .title1)
    }
}

fileprivate final class PlaybackSlider: ChatTimelineObservableSlider {
    
    var inset: CGFloat = -0.5
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        return super.trackRect(forBounds: bounds).insetBy(dx: -3.0, dy: inset)
    }
}

//fileprivate func generateThumbImage(size: CGSize, category: UIFont.TextStyle, color: UIColor) -> UIImage? {
//    let basicCanvasSize = CGSize(width: 15, height: 15)
//    let scaledCanvasSize = basicCanvasSize.scaled(category: category)
//    let scaledCanvasBounds = CGRect(origin: .zero, size: scaledCanvasSize)
//    let thumbInsets = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
//    let thumbFrame = scaledCanvasBounds.jv_reduceBy(insets: thumbInsets)
//
//    let thumbLayer = CALayer()
//    thumbLayer.frame = thumbFrame
//    thumbLayer.backgroundColor = color.cgColor
//    thumbLayer.cornerRadius = thumbFrame.width * 0.5
//    thumbLayer.allowsEdgeAntialiasing = true
//
//    let parentLayer = CALayer()
//    parentLayer.frame = scaledCanvasBounds
//    parentLayer.allowsEdgeAntialiasing = true
//    parentLayer.addSublayer(thumbLayer)
//
//    UIGraphicsBeginImageContextWithOptions(scaledCanvasSize, false, 0)
//    defer { UIGraphicsEndImageContext() }
//
//    if let context = UIGraphicsGetCurrentContext() {
//        parentLayer.render(in: context)
//        return UIGraphicsGetImageFromCurrentImageContext()
//    }
//    else {
//        return nil
//    }
//}

fileprivate func obtainDurationFont() -> UIFont {
    return JVDesign.fonts.resolve(.medium(14), scaling: .caption1)
}
