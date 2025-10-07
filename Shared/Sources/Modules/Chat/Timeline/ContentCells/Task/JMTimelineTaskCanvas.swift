//
//  JMTimelineTaskCanvas.swift
//  App
//
//  Created by Julia Popova on 13.09.24.
//

import UIKit
import DTModelStorage
import JMRepicKit
import JMTimelineKit

final class JMTimelineTaskCanvas: JMTimelineCanvas {
    var completeHandler: (() -> Void)?
    var editHandler: (() -> Void)?
    
    private var lastActionTime: Date?
    
//    private let plainBlock = UILabel()
    private let containerView = UIView()
    
    private let checkmarkImage = UIImageView()
    private let taskNameLabel = UILabel()
    private let notifyAtLabel = UILabel()
    private let statusLabel = UILabel()
    private let bellImageView = UIImageView()
    
    private let agentNameLabel = UILabel()
    private var agentRepic: JMRepicView = .init(config: JMRepicConfig.standard())
    
    private let completionArea = UIControl()
    private let editArea = UIControl()
    
    private let overlay = UIView()
    
    override init() {
        super.init()
        taskNameLabel.font = JVDesign.fonts.resolve(.regular(16), scaling: .callout)
        taskNameLabel.numberOfLines = Int.max
        
        agentNameLabel.font = JVDesign.fonts.resolve(.regular(13), scaling: .body)
        agentNameLabel.numberOfLines = Int.max
        
        notifyAtLabel.font = JVDesign.fonts.resolve(.regular(13), scaling: .body)
        notifyAtLabel.numberOfLines = Int.max
        
        statusLabel.font = JVDesign.fonts.resolve(.regular(11), scaling: .body)
        statusLabel.numberOfLines = Int.max
        
//        plainBlock.font = JVDesign.fonts.resolve(.regular(12), scaling: .caption1)
//        plainBlock.textColor = JVDesign.colors.resolve(usage: .secondaryForeground)
        
        containerView.addSubview(checkmarkImage)
        containerView.addSubview(taskNameLabel)
        containerView.addSubview(agentNameLabel)
        containerView.addSubview(agentRepic)

        containerView.addSubview(bellImageView)
        containerView.addSubview(notifyAtLabel)
        containerView.addSubview(statusLabel)

        containerView.addSubview(completionArea)
        containerView.addSubview(editArea)
        containerView.addSubview(overlay)

//        addSubview(plainBlock)
        addSubview(containerView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }
    
    override func configure(item: JMTimelineItem) {
        super.configure(item: item)
        
        completionArea.addTarget(self, action: #selector(handleCompletionAreaTap), for: .touchUpInside)
        editArea.addTarget(self, action: #selector(handleEditAreaTap), for: .touchUpInside)
        
        if let item = (item as? JMTimelineTaskItem) {
            let taskName = item.payload.taskName?.jv_valuable ?? loc["Task.NoDescription"]
            
            taskNameLabel.text = taskName
            
            containerView.backgroundColor = JVDesign.colors.resolve(usage: .primaryBackground)
            taskNameLabel.textColor = JVDesign.colors.resolve(usage: .primaryLabel)
            agentNameLabel.textColor = JVDesign.colors.resolve(usage: .primaryLabel)
            notifyAtLabel.textColor = JVDesign.colors.resolve(usage: .secondaryLabel)
            statusLabel.textColor = JVDesign.colors.resolve(usage: .secondaryLabel)
            
            if #available(iOS 13.0, *) {
                containerView.layer.borderColor = JVDesign.colors.resolve(usage: .secondaryFill).cgColor
            }
            
            completionArea.backgroundColor = .clear
            editArea.backgroundColor = .clear
            
            overlay.backgroundColor = JVDesign.colors.resolve(usage: .chattingBackground).withAlphaComponent(0.5)
            
            notifyAtLabel.textColor = JVDesign.colors.resolve(usage: .secondaryLabel)
            
            if #available(iOS 13.0, *) {
                bellImageView.image = UIImage(named: item.payload.notificationEnabled ? "bell_on" : "bell_off")?.withTintColor(JVDesign.colors.resolve(usage: .secondaryLabel), renderingMode: .alwaysOriginal)
            }
            switch item.payload.taskStatus {
            case .created:
                if let date = item.payload.createdAt {
                    let loc = loc[format: "Task.Created.Short", item.payload.provider.formattedDateForTaskNotification(date)]
                    statusLabel.text = loc
                } else {
//                    assertionFailure()
                }
            case .updated, .completed:
                if let date = item.payload.updatedAt {
                    let loc = loc[format: "Task.Modified.Short", item.payload.provider.formattedDateForTaskNotification(date)]
                    statusLabel.text = loc
                } else if let date = item.payload.createdAt {
                    let loc = loc[format: "Task.Created.Short", item.payload.provider.formattedDateForTaskNotification(date)]
                    statusLabel.text = loc
                }
            case .deleted:
                if let date = item.payload.updatedAt {
                    let loc = loc[format: "Task.Deleted.Short", item.payload.provider.formattedDateForTaskNotification(date)]
                    statusLabel.text = loc
                } else {
//                    assertionFailure()
                }
            case .fired:
                let createdAt = item.payload.createdAt
                let updatedAt = item.payload.updatedAt
                
                if let updatedAt = updatedAt, updatedAt != createdAt {
                    let loc = loc[format: "Task.Modified.Short", item.payload.provider.formattedDateForTaskNotification(updatedAt)]
                    statusLabel.text = loc
                } else if let createdAt = createdAt {
                    let loc = loc[format: "Task.Created.Short", item.payload.provider.formattedDateForTaskNotification(createdAt)]
                    statusLabel.text = loc
                } else {
                    statusLabel.text = String()
//                    assertionFailure()
                }
                notifyAtLabel.textColor = UIColor.red
                if #available(iOS 13.0, *) {
                    bellImageView.image = UIImage(named: item.payload.notificationEnabled ? "bell_on" : "bell_off")?.withTintColor(UIColor.red, renderingMode: .alwaysOriginal)
                }
            case .unknown:
                assertionFailure()
            }
            
            if #available(iOS 13.0, *) {
                if item.payload.taskStatus == .completed {
                    
                    let image = UIImage(named: "checkbox.fill.green")?.withRenderingMode(.alwaysOriginal)
                    checkmarkImage.image = image
                    
                    overlay.isHidden = false
                    isUserInteractionEnabled = false
                } else if item.payload.taskStatus == .deleted {
                    let image = UIImage(named: "xmark.circle.fill.red")?.withRenderingMode(.alwaysOriginal)
                    checkmarkImage.image = image
                    
                    overlay.isHidden = false
                    isUserInteractionEnabled = false
                } else {
                    let image = UIImage(named: "checkbox.gray")?.withRenderingMode(.alwaysOriginal)
                    checkmarkImage.image = image
                    
                    overlay.isHidden = true
                    isUserInteractionEnabled = true
                }
            }
            
            agentNameLabel.text = item.payload.username
            
            if let date = item.payload.notifyAt {
                notifyAtLabel.text = item.payload.provider.formattedDateForTaskNotification(date)
            } else {
                assertionFailure()
            }
            
            if let userRepic = item.payload.userRepic {
                agentRepic.configure(item: userRepic)
            }
            
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = Layout(
            size: bounds.size,
//            plainBlock: plainBlock,
            taskNameLabel: taskNameLabel,
            agentNameLabel: agentNameLabel,
            statusLabel: statusLabel,
            notifyAtLabel: notifyAtLabel
        )
        
        checkmarkImage.frame = layout.checkmarkImageViewFrame
        taskNameLabel.frame = layout.taskNameLabelFrame
//        plainBlock.frame = layout.plainBlockFrame
        agentRepic.frame = layout.agentRepicFrame
        agentNameLabel.frame = layout.agentNameLabelFrame
        bellImageView.frame = layout.bellImageViewFrame
        notifyAtLabel.frame = layout.notifyAtLabelFrame
        statusLabel.frame = layout.statusLabelFrame
        completionArea.frame = layout.completionAreaFrame
        editArea.frame = layout.editAreaFrame
        overlay.frame = layout.overlayFrame
        containerView.frame = layout.containerViewFrame
        containerView.layer.borderWidth = 1.0
        containerView.layer.cornerRadius = 10.0
        
        overlay.frame = layout.overlayFrame
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = Layout(
            size: size,
//            plainBlock: plainBlock,
            taskNameLabel: taskNameLabel,
            agentNameLabel: agentNameLabel,
            statusLabel: statusLabel,
            notifyAtLabel: notifyAtLabel
        )
        
        return .init(width: size.width, height: layout.containerViewFrame.maxY)
    }
    
    @objc func handleEditAreaTap() {
        editHandler?()
    }
    
    @objc func handleCompletionAreaTap() {
        completeHandler?()
    }
}

fileprivate struct Layout {
    let size: CGSize
//    let plainBlock: UILabel
    let taskNameLabel: UILabel
    let agentNameLabel: UILabel
    let statusLabel: UILabel
    let notifyAtLabel: UILabel
    
    let containerHorizontalPadding = 10.0
    let textHorizontalPadding = 10.0
    
    var containerWidth: CGFloat {
        return size.width - (16.0 * 2)
    }
    
    let itemInsets = 12.0
    
//    var plainBlockFrame: CGRect {
//        let plainBlockSize = plainBlock.jv_size(forWidth: containerWidth)
//        
//        return CGRect(
//            x: (size.width - plainBlockSize.width) * 0.5,
//            y: 0.0,
//            width: plainBlockSize.width,
//            height: plainBlockSize.height
//        )
//    }
    
    var checkmarkImageViewFrame: CGRect {
        .init(
            x: itemInsets,
            y: itemInsets,
            width: 18,
            height: 18
        )
    }
    
    var taskNameLabelFrame: CGRect {
        let width = bellImageViewFrame.minX - checkmarkImageViewFrame.maxX - (itemInsets * 2)
        let size = taskNameLabel.sizeThatFits(
            CGSize(
            width: width,
            height: .greatestFiniteMagnitude
            )
        )
        
        return CGRect(
            origin: .init(
                x: checkmarkImageViewFrame.maxX + itemInsets,
                y: itemInsets
            ),
            size: .init(
                width: width,
                height: size.height
            )
        )
    }
    
    var agentRepicFrame: CGRect {
        return .init(
            x: checkmarkImageViewFrame.maxX + textHorizontalPadding,
            y: taskNameLabelFrame.maxY + 11.0,
            width: 16,
            height: 16
        )
    }
    
    var agentNameLabelFrame: CGRect {
        let size = agentNameLabel.sizeThatFits(CGSize(width: containerWidth - checkmarkImageViewFrame.maxX - (2 * textHorizontalPadding), height: .greatestFiniteMagnitude))
        
        return CGRect(
            origin: .init(
                x: agentRepicFrame.maxX + 4,
                y: taskNameLabelFrame.maxY + 11.0
            ),
            size: .init(
                width: size.width,
                height: size.height
            )
        )
    }
    
    var bellImageViewFrame: CGRect {
        return .init(
            origin: .init(
                x: notifyAtLabelFrame.minX - 2 - 14,
                y: notifyAtLabelFrame.minY + ((notifyAtLabelFrame.height - 14) / 2)
            ), size: .init(
                width: 14,
                height: 14
            )
        )
    }
    
    var notifyAtLabelFrame: CGRect {
        let size = notifyAtLabel.sizeThatFits(CGSize(width: containerWidth - checkmarkImageViewFrame.maxX - (2 * textHorizontalPadding), height: .greatestFiniteMagnitude))
        
        return CGRect(
            origin: .init(
                x: containerWidth - size.width - itemInsets,
                y: itemInsets
            ),
            size: .init(
                width: size.width,
                height: size.height
            )
        )
    }
    
    var statusLabelFrame: CGRect {
        let size = statusLabel.sizeThatFits(CGSize(width: containerWidth - (2 * textHorizontalPadding) - agentNameLabelFrame.maxX, height: .greatestFiniteMagnitude))
        
        return CGRect(
            origin: .init(
                x: containerWidth - size.width - itemInsets,
                y: agentNameLabelFrame.minY
            ),
            size: .init(
                width: size.width,
                height: size.height
            )
        )
    }
    
    var completionAreaFrame: CGRect {
        return .init(
            x: 0,
            y: 0,
            width: taskNameLabelFrame.minX,
            height: agentNameLabelFrame.maxY + itemInsets
        )
    }
    
    var editAreaFrame: CGRect {
        return .init(
            x: completionAreaFrame.maxX,
            y: 0,
            width: size.width - completionAreaFrame.maxX,
            height: agentNameLabelFrame.maxY + itemInsets
        )
    }
    
    var overlayFrame: CGRect {
        return .init(origin: .init(x: 0, y: 0), size: size)
    }
    
    var containerViewFrame: CGRect {
        let totalHeight = agentNameLabelFrame.maxY + itemInsets
        return CGRect(
            origin: .init(x: 16, y: 16),
//            origin: .init(x: 16, y: plainBlockFrame.maxY + 16),
            size: .init(
                width: containerWidth,
                height: totalHeight
            )
        )
    }
}
