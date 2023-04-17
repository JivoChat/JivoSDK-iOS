//
//  ChatReplyAttachmentBar.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 18.11.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation

import UIKit

final class ChatReplyAttachmentBar: UIScrollView {
    var contentTapHandler: ((Int) -> Void)?
    var dismissTapHandler: ((Int) -> Void)?
    
    var controls = [UUID: ChatReplyAttachmentControl]()
    var orderedControls = [ChatReplyAttachmentControl]()
    
    var attachmentsCount: Int {
        controls.count
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        showsHorizontalScrollIndicator = false
        clipsToBounds = false
    }

    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    var hasAttachments: Bool {
        return !controls.isEmpty
    }
    
    var isDownloading: Bool {
        let payloads = orderedControls.map({ $0.payload })
        for payload in payloads {
            guard case .progress = payload else { continue }
            return true
        }
        
        return false
    }
    
    func update(attachment: ChatPhotoPickerObject) {
        if let control = controls[attachment.uuid] {
            control.payload = attachment.payload
        }
        else {
            let control = ChatReplyAttachmentControl(payload: attachment.payload)
            controls[attachment.uuid] = control
            orderedControls.append(control)
            addSubview(control)
            
            layoutIfNeeded()
            scrollRectToVisible(
                CGRect(x: control.frame.maxX - 1, y: 0, width: 1, height: 1),
                animated: true
            )
            
            control.contentTapHandler = { [weak self] in
                guard let index = self?.orderedControls.firstIndex(of: control) else { return }
                self?.contentTapHandler?(index)
            }
            
            control.dismissTapHandler = { [weak self] in
                guard let index = self?.orderedControls.firstIndex(of: control) else { return }
                self?.dismissTapHandler?(index)
            }
        }
    }
    
    func remove(at index: Int) -> Int {
        let control = orderedControls.remove(at: index)
        control.removeFromSuperview()
        
        if let index = controls.values.firstIndex(of: control) {
            controls.remove(at: index)
        }
        
        return orderedControls.count
    }
    
    func removeAll() {
        orderedControls.forEach { $0.removeFromSuperview() }
        controls.removeAll()
        orderedControls.removeAll()
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let layout = getLayout(size: bounds.size)
        zip(orderedControls, layout.orderedControlsFrames).forEach { subview, frame in subview.frame = frame }
        contentSize = layout.contentSize
    }

    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            orderedControls: orderedControls
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let orderedControls: [ChatReplyAttachmentControl]

    private let height = CGFloat(40)
    private let gap = CGFloat(15)
    
    var orderedControlsFrames: [CGRect] {
        var rect = CGRect(x: 0, y: 0, width: 0, height: bounds.height)
        return orderedControls.map { control in
            defer { rect.origin.x += rect.width + gap }
            rect.size.width = control.sizeThatFits(rect.size).width
            return rect
        }
    }
    
    var contentSize: CGSize {
        let width = orderedControlsFrames.last?.maxX ?? 0
        return CGSize(width: width, height: height)
    }

    var totalSize: CGSize {
        return CGSize(width: bounds.width, height: height)
    }
}
