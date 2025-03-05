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

enum JMTimelineCompositePlayableItem: Equatable {
    case audio
    case voice(JMTimelineCompositeVoiceStyle)
}

enum JMTimelineCompositeVoiceStyle: Equatable {
    case standard
    case preview
}

struct JMTimelineCompositeAudioStyle: JMTimelineStyle {
    let tintColor: UIColor
}

struct JMTimelineCompositeAudioStyleExtended: JMTimelineStyle {
    let underlayColor: UIColor
    let buttonTintColor: UIColor
    let buttonBorderColor: UIColor
    let buttonBackgroundColor: UIColor
    let minimumTrackColor: UIColor
    let maximumTrackColor: UIColor
    let durationLabelColor: UIColor
    let waveformColor: UIColor
}

final class JMTimelineCompositeAudioBlock: JMTimelineBlock {
    private let underlay = UIView()
    private let playButton = UIButton()
    private let pauseButton = UIButton()
    private let sliderControl = PlaybackSlider()
    private let durationLabel = UILabel()
    
    private var item: URL?
    private var duration: TimeInterval?
    private var sliderColor = UIColor.clear
    private var extendedStyle: JMTimelineCompositeAudioStyleExtended?
    private var waveFormView = UIImageView()
    
    private var firstVoiceImageRequestTime: Date?
    
    private var type: JMTimelineCompositePlayableItem
    
    private let loadingQueue: DispatchQueue
    
    private let loadingSecLimit: UInt64 = 3
    
    init(type: JMTimelineCompositePlayableItem) {
        
        self.loadingQueue = DispatchQueue(label: "rmo.waveform-drawer.queue", qos: .userInteractive, attributes: .concurrent)
        
        self.type = type
        
        super.init()
        
        clipsToBounds = false
        
        addSubview(underlay)
        
        addSubview(waveFormView)
        
        let resumeIcon = UIImage.jv_named("player_resume")?.withRenderingMode(.alwaysTemplate)
        playButton.setImage(resumeIcon, for: .normal)
        playButton.setImage(resumeIcon, for: .highlighted)
        playButton.contentVerticalAlignment = .center
        playButton.contentHorizontalAlignment = .center
        playButton.addTarget(self, action: #selector(handlePlayButton), for: .touchUpInside)
        addSubview(playButton)
        
        let pauseIcon = UIImage.jv_named("player_pause")?.withRenderingMode(.alwaysTemplate)
        pauseButton.setImage(pauseIcon, for: .normal)
        pauseButton.setImage(pauseIcon, for: .highlighted)
        pauseButton.contentVerticalAlignment = .center
        pauseButton.contentHorizontalAlignment = .center
        pauseButton.addTarget(self, action: #selector(handlePauseButton), for: .touchUpInside)
        addSubview(pauseButton)
        
        switch type {
        case .audio:
            sliderControl.inset = -0.5
        case .voice(let type) where type == .preview:
            sliderControl.inset = -10.0
        case .voice:
            sliderControl.inset = -25.0
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
        
        guard let style = extendedStyle else { return }
        
        underlay.backgroundColor = style.underlayColor
        
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
        durationLabel.font = JVDesign.fonts.resolve(.medium(14), scaling: .caption1)
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
        
        underlay.frame = bounds
        underlay.layer.cornerRadius = underlay.frame.height * 0.5
        
        switch type {
        case .audio:
            underlay.layer.cornerRadius = 0
            waveFormView.isHidden = true
        case .voice(.preview):
            underlay.layer.cornerRadius = layout.buttonCornerRadius
        case .voice(.standard):
            layer.cornerRadius = self.frame.height * 0.5
            clipsToBounds = true
        }
        
        playButton.frame = layout.buttonFrame
        playButton.layer.cornerRadius = layout.buttonCornerRadius
        pauseButton.frame = layout.buttonFrame
        pauseButton.layer.cornerRadius = layout.buttonCornerRadius
        sliderControl.frame = layout.sliderControlFrame
        durationLabel.frame = layout.durationLabelFrame
        waveFormView.frame = layout.waveformFrame
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        drawWaveformIfNeeded()
        updateDesignWithExtendedStyle()
    }
    
    private func getLayout(size: CGSize, type: JMTimelineCompositePlayableItem) -> Layout {
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
    }
    
    private func unsubscribe() {
        NotificationCenter.default.removeObserver(self)
        
        if let item = item {
            interactor?.stopMedia(item: item)
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
        case .none, .failed:
            playButton.isHidden = false
            pauseButton.isHidden = true
            sliderControl.value = 0
            durationLabel.text = duration.flatMap { generateProgressCaption(current: 0, duration: $0) }
            
        case .loading:
            playButton.isHidden = true
            pauseButton.isHidden = false
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
        guard let item = item,
              waveFormView.image == nil
        else {
            return
        }
        
        switch type {
        case .audio:
            break
        case .voice(let value):
            switch value {
            case .standard:
                let workItem = DispatchWorkItem(flags: .jv_empty) { [weak self] in
                    guard let `self` = self else { return }
                    if self.waveFormView.image == nil {
                        let samples = item.absoluteString.jv_sha512().map({ return Float($0) })
                        self.drawWavefromImage(for: samples)
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: loadingSecLimit * 1000 * 1000 * 1000), execute: workItem)
                
                provider?.requestWaveformPoints(from: item, completion: { [weak self] result in
                    guard let `self` = self, let result, item == self.item, waveFormView.image == nil else { return }
                    
                    switch result {
                    case .value(let meta, let kind):
                        switch kind {
                        case .binary:
                            let data = NSData(contentsOf: meta.localUrl) ?? NSData()
                            loadingQueue.async { [weak self] in
                                let bytes = [UInt8](data)
                                let samples = bytes.map { Float($0) }
                                
                                DispatchQueue.main.async {
                                    self?.drawWavefromImage(for: samples)
                                    workItem.cancel()
                                }
                            }
                        default: break
                        }
                        
                    case .waiting, .failure: break
                    }
                })
            case .preview:
                let asset = AVAsset(url: item)
                let audioTracks: [AVAssetTrack] = asset.tracks(withMediaType: AVMediaType.audio)
                if let track: AVAssetTrack = audioTracks.first {
                    let width = Int(getLayout(size: bounds.size, type: .voice(.preview)).sliderControlFrame.width)
                    WaveformSamplesExtractor.shared.samples(
                        audioTrack: track,
                        desiredNumberOfSamples: width,
                        onSuccess: { samples, _, _ in
                            self.drawWavefromImage(for: samples)
                        }, onFailure: {
                            assertionFailure()
                        }
                    )
                }
            }
        }
    }
    
    private func drawWavefromImage(for samples: [Float]) {
        switch type {
        case .voice(.preview):
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
                configuration: configuration
            )
        case .voice(.standard):
            let configuration = WaveformConfiguration(
                size:  self.waveFormView.bounds.size,
                color: extendedStyle?.waveformColor ?? UIColor.white,
                backgroundColor: UIColor.clear,
                lineWidth: 4,
                space: 2,
                pickToPickAmplitude: 20.0
            )
            self.waveFormView.image = WaveFormDrawer.shared.image(
                samples: samples,
                configuration: configuration
            )
        case .audio:
            assertionFailure()
            break
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
    let type: JMTimelineCompositePlayableItem
    
    var buttonFrame: CGRect {
        switch type {
        case .audio, .voice(type: .standard):
            let size = CGSize(width: 38, height: 38)
            let buttonSize = JVDesign.fonts.scaled(size, category: .title1)
            
            return CGRect(x: 5, y: 5, width: buttonSize.width, height: buttonSize.height)
        case .voice:
            return CGRect(x: 0, y: 0, width: bounds.height, height: bounds.height)
        }
    }
    
    var buttonCornerRadius: CGFloat {
        return buttonFrame.height * 0.5
    }
    
    var sliderControlFrame: CGRect {
        let horizontalPadding = CGFloat(12)
        let leftX = buttonFrame.maxX + horizontalPadding
        
        switch type {
        case .audio, .voice(type: .standard):
            if durationLabel.jv_hasText {
                let width = bounds.width - leftX
                let height = CGFloat(15)
                let topY = buttonFrame.minY
                return CGRect(
                    x: leftX,
                    y: topY,
                    width: width - horizontalPadding,
                    height: height
                )
            } else {
                let width = bounds.width - leftX - horizontalPadding
                let height = CGFloat(15)
                let topY = buttonFrame.midY - height + 2
                return CGRect(
                    x: leftX,
                    y: topY,
                    width: width,
                    height: height
                )
            }
        case .voice:
            let width = durationLabelFrame.minX - buttonFrame.maxX - (horizontalPadding * 2)
            return CGRect(
                x: leftX,
                y: bounds.origin.y,
                width: width,
                height: bounds.height
            )
        }
    }
    
    var durationLabelFrame: CGRect {
        switch type {
        case .audio, .voice(.standard):
            let size = durationLabel.sizeThatFits(.zero)
            let topY = sliderControlFrame.maxY + 15
            
            if durationLabel.jv_hasText {
                let leftX = buttonFrame.maxX + 12.0
                return CGRect(x: leftX,
                              y: buttonFrame.maxY - size.height,
                              width: size.width,
                              height: size.height
                )
            }
            else {
                return CGRect(x: bounds.width, y: topY, width: 0, height: 0)
            }
        case .voice(.preview):
            let label = UILabel()
            label.text = "0:00/0:00"
            label.font = label.font
            let size = label.sizeThatFits(.zero)
            let topY = buttonFrame.minY + (buttonFrame.height - size.height) * 0.5
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
        let height = max(buttonFrame.maxY + 5, durationLabelFrame.maxY)
        return CGSize(width: bounds.width, height: height)
    }
    
    var waveformFrame: CGRect {
        return CGRect(
            x: sliderControlFrame.minX,
            y: type == .voice(.standard) ? -10.0 : 0.0,
            width: sliderControlFrame.width,
            height: bounds.height
        )
    }
}

fileprivate final class PlaybackSlider: ChatTimelineObservableSlider {
    var inset: CGFloat = -0.5
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        return super.trackRect(forBounds: bounds).insetBy(dx: -3.0, dy: inset)
    }
}
