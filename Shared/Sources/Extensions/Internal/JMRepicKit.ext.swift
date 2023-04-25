//
//  JMRepicKit.ext.swift
//  JMTimeline
//
//  Created by Stan Potemkin on 29/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import JivoFoundation
import JMRepicKit

enum JMRepicActivity {
    case calling
    case taskActive
    case taskFired
}

extension JMRepicConfig {
    static func standard(height: CGFloat = 75, context: JMRepicView.VisualContext = .regular) -> JMRepicConfig {
        return JMRepicConfig(
            side: height,
            borderWidth: 0,
            borderColor: .clear,
            itemConfig: JMRepicItemConfig(
                borderWidthProvider: { $0 * 0.05 },
                borderColor: context.resolvedColor
            ),
            layoutMap: [
                1: [
                    JMRepicLayoutItem(position: CGPoint(x: 0, y: 0), radius: 1.0)
                ],
                2: [
                    JMRepicLayoutItem(position: CGPoint(x: 0.15, y: -0.15), radius: 0.65),
                    JMRepicLayoutItem(position: CGPoint(x: -0.15, y: 0.15), radius: 0.65)
                ],
                .max: [
                    JMRepicLayoutItem(position: CGPoint(x: 0.10, y: -0.25), radius: 0.55),
                    JMRepicLayoutItem(position: CGPoint(x: -0.25, y: 0.08), radius: 0.55),
                    JMRepicLayoutItem(position: CGPoint(x: 0.18, y: 0.20), radius: 0.55)
                ]
            ]
        )
    }
    
    static func overlay(height: CGFloat = 75) -> JMRepicConfig {
        return JMRepicConfig(
            side: height,
            borderWidth: 0,
            borderColor: .clear,
            itemConfig: JMRepicItemConfig(
                borderWidthProvider: { $0 * 0.05 },
                borderColor: JVDesign.colors.resolve(usage: .primaryBackground)
            ),
            layoutMap: [
                .max: [
                    JMRepicLayoutItem(position: CGPoint(x: 0, y: 0), radius: 1.0),
                    JMRepicLayoutItem(position: CGPoint(x: 0, y: 0), radius: 1.0)
                ]
            ]
        )
    }
}

extension JMRepicView {
    class func standard(height: CGFloat = 75) -> JMRepicView {
        return JMRepicView(
            config: JMRepicConfig(
                side: height,
                borderWidth: 0,
                borderColor: .clear,
                itemConfig: JMRepicItemConfig(
                    borderWidthProvider: { _ in 0 },
                    borderColor: .clear
                ),
                layoutMap: [
                    1: [JMRepicLayoutItem(position: .zero, radius: 1.0)]
                ]
            )
        )
    }
    
    func configure(attendees: [JVPresentable], transparent: Bool, repicContext: JMRepicView.VisualContext, primaryScale: CGFloat?, indicatorScale: CGFloat? = nil) {
        let images = attendees.compactMap { $0.repicItem(transparent: transparent, scale: primaryScale) }
        configure(items: images)
        
        if let attendee = attendees.first, attendee.jv_isValid {
            switch attendee.senderType {
            case .`self`:
                break
                
            case .agent:
                guard let agent = attendee as? JVAgent else { return }

                if agent.onCall {
                    setActivity(agent.onCall ? .calling : nil, context: repicContext)
                }
                else {
                    setStatus(agent.state, worktimeEnabled: agent.isWorktimeEnabled, context: repicContext, scale: indicatorScale ?? 0.25)
                }
                
            case .bot:
                break

            case .client:
                guard let client = attendee as? JVClient else { return }
                
                if client.hasActiveCall {
                    setActivity(.calling, context: repicContext)
                }
                else if let task = client.task {
                    switch task.status {
                    case .active: setActivity(.taskActive, context: repicContext)
                    case .fired: setActivity(.taskFired, context: repicContext)
                    case .unknown: setActivity(nil, context: repicContext)
                    }
                }
                else {
                    setActivity(nil, context: repicContext)
                }
                
            case .guest:
                break
                
            case .teamchat:
                break
                
            case .department:
                break
            }
        }
    }
    
    func setActivity(_ activity: JMRepicActivity?, context: JMRepicView.VisualContext) {
        switch activity {
        case .calling?:
            setIndicator(
                fillColor: JVDesign.colors.resolve(usage: .activityCall),
                icon: UIImage(named: "activity_oncall")?.withRenderingMode(.alwaysTemplate),
                config: .activityIndicatorConfig(context: context)
            )

        case .taskActive?:
            setIndicator(
                fillColor: JVDesign.colors.resolve(usage: .activityActiveTask),
                icon: UIImage(named: "activity_reminder")?.withRenderingMode(.alwaysTemplate),
                config: .activityIndicatorConfig(context: context)
            )
            
        case .taskFired?:
            setIndicator(
                fillColor: JVDesign.colors.resolve(usage: .activityFiredTask),
                icon: UIImage(named: "activity_reminder")?.withRenderingMode(.alwaysTemplate),
                config: .activityIndicatorConfig(context: context)
            )
            
        default:
            setIndicator(
                fillColor: .clear,
                icon: nil,
                config: nil
            )
        }
    }
    
    func setSleeping(icon: UIImage?, context: VisualContext) {
        if let _ = icon {
            setIndicator(
                fillColor: .clear,
                icon: icon,
                config: .statusIndicatorConfig(indicatorScale: 0.8, context: context)
            )
        }
        else {
            setIndicator(
                fillColor: .clear,
                icon: nil,
                config: nil
            )
        }
    }
    
    enum VisualContext: String {
        case regular = "def"
        case navigation = "nav"
        case group = "grp"
    }
    
    func setStatus(_ state: JVAgentState, worktimeEnabled: Bool, context: VisualContext, scale: CGFloat) {
        switch state {
        case .active where worktimeEnabled:
            setIndicator(
                fillColor: .clear,
                icon: UIImage(named: "status_\(context.rawValue)_online"),
                config: .statusIndicatorConfig(indicatorScale: scale, context: context)
            )
            
        case .active:
            setIndicator(
                fillColor: .clear,
                icon: UIImage(named: "status_\(context.rawValue)_online_sleep"),
                config: .statusIndicatorConfig(indicatorScale: scale, context: context)
            )

        case .away where worktimeEnabled:
            setIndicator(
                fillColor: .clear,
                icon: UIImage(named: "status_\(context.rawValue)_away"),
                config: .statusIndicatorConfig(indicatorScale: scale, context: context)
            )

        case .away:
            setIndicator(
                fillColor: .clear,
                icon: UIImage(named: "status_\(context.rawValue)_away_sleep"),
                config: .statusIndicatorConfig(indicatorScale: scale, context: context)
            )

        case .none:
            setIndicator(
                fillColor: .clear,
                icon: nil,
                config: nil
            )
        }
    }
}

fileprivate extension JMRepicIndicatorConfig {
    static func statusIndicatorConfig(indicatorScale: CGFloat, context: JMRepicView.VisualContext) -> JMRepicIndicatorConfig {
        return JMRepicIndicatorConfig(
            sideProvider: { $0 * indicatorScale },
            borderWidthProvider: { _ in 0 },
            borderColor: context.resolvedColor,
            contentMarginProvider: { _ in 0 },
            contentTintColor: JVDesign.colors.resolve(usage: .primaryForeground)
        )
    }
    
    static func activityIndicatorConfig(context: JMRepicView.VisualContext) -> JMRepicIndicatorConfig {
        return JMRepicIndicatorConfig(
            sideProvider: { max(16, $0 * 0.3) },
            borderWidthProvider: { max(2, $0 * 0.035) },
            borderColor: context.resolvedColor,
            contentMarginProvider: { $0 * 0.031 },
            contentTintColor: JVDesign.colors.resolve(usage: .white)
        )
    }
}

fileprivate extension JMRepicView.VisualContext {
    var resolvedColor: UIColor {
        switch self {
        case .regular: return JVDesign.colors.resolve(usage: .primaryBackground)
        case .navigation: return JVDesign.colors.resolve(usage: .navigatorBackground)
        case .group: return JVDesign.colors.resolve(usage: .groupingBackground)
        }
    }
}
