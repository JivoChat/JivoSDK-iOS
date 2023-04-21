//  
//  ChatModuleView.swift
//  Pods
//
//  Created by Stan Potemkin on 11.08.2022.
//

import Foundation
import UIKit
#if canImport(JivoFoundation)
import JivoFoundation
#endif
import BABFrameObservingInputAccessoryView
import JMTimelineKit
import JMRepicKit


enum ChatModuleViewIntent {
    case didLoad
    case willAppear
    case prepareAttachButton(button: UIButton)
    case textDidChange(text: String)
    case attachmentDidDismiss(index: Int)
    case sendMessage(text: String)
    case messageTap(itemUUID: String, interaction: ChatTimelineTap)
    case mediaTap(url: URL, mime: String?)
    case requestDeveloperMenu(anchor: UIView)
    case timelineEvent(JMTimelineEvent)
    case dismiss
}

typealias ChatModuleView = (
    // Feed free to replace it with *ViewController or *NavigationController
    ChatModuleViewController
)

typealias ChatModuleNavigationController = JVChatModuleNavigationController
final class JVChatModuleNavigationController
: RTEModuleViewNavigatable<
    ChatModulePresenterUpdate,
    ChatModuleViewIntent
> {
    init(pipeline: RTEModulePipelineViewNotifier<ChatModuleViewIntent>, keyboardObservingBar: BABFrameObservingInputAccessoryView, timelineController: JMTimelineController<ChatTimelineInteractor>, timelineInteractor: ChatTimelineInteractor, uiConfig: ChatModuleUIConfig, closeButton: JVDisplayCloseButton) {
        super.init(
            primaryView: ChatModuleViewController(
                pipeline: pipeline,
                keyboardObservingBar: keyboardObservingBar,
                timelineController: timelineController,
                timelineInteractor: timelineInteractor,
                uiConfig: uiConfig,
                closeButton: closeButton
            )
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

typealias ChatModuleViewController = JVChatModuleViewController
final class JVChatModuleViewController
: RTEModuleViewStandalone<
    ChatModulePresenterUpdate,
    ChatModuleViewIntent
>
, NavigationBarConfigurator {
    private lazy var titleControl = JVChatTitleControl()
    private lazy var copyrightControl = JVChatCopyrightControl()
    private lazy var replyUnderlay = UIView()
    private lazy var replyControl = SdkChatReplyControl()
    
    private let keyboardObservingBar: BABFrameObservingInputAccessoryView
    private let timelineController: JMTimelineController<ChatTimelineInteractor>
    private let timelineInteractor: ChatTimelineInteractor
    private let uiConfig: ChatModuleUIConfig
    
    private let placeholderView = PlaceholderViewController<SdkEngine>(satellite: nil, layout: .center)
    private(set) var collectionView: UICollectionView?
    private var keyboardHeight = CGFloat(0)
    
    private let timelineControlTapDelegate = TimelineControlTapDelegate()

    init(pipeline: RTEModulePipelineViewNotifier<ChatModuleViewIntent>, keyboardObservingBar: BABFrameObservingInputAccessoryView, timelineController: JMTimelineController<ChatTimelineInteractor>, timelineInteractor: ChatTimelineInteractor, uiConfig: ChatModuleUIConfig, closeButton: JVDisplayCloseButton) {
        self.keyboardObservingBar = keyboardObservingBar
        self.timelineController = timelineController
        self.timelineInteractor = timelineInteractor
        self.uiConfig = uiConfig
        
        super.init(pipeline: pipeline)
        
        navigationItem.titleView = titleControl
        navigationItem.jv_largeDisplayMode = .never
        
        edgesForExtendedLayout = []
        
        switch closeButton {
        case .omit:
            break
        case .back:
            configureNavigationBar(
                button: .back,
                target: self,
                backButtonTapAction: #selector(handleDismissButtonTap))
        case .dismiss:
            configureNavigationBar(
                button: .dismiss,
                target: self,
                backButtonTapAction: #selector(handleDismissButtonTap))
        }
        
        recreateTableView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if let timelineView = collectionView as? JMTimelineView<ChatTimelineInteractor> {
            timelineController.detach(timelineView: timelineView)
        }
    }
    
    override func handlePresenter(update: ChatModulePresenterUpdate) {
        switch update {
        case .primaryLayout(.loading):
            prepareLayoutAsLoading()
        case .primaryLayout(.chatting):
            prepareLayoutAsChatting()
        case .primaryLayout(.unavailable):
            prepareLayoutAsUnavailable()
        case .headerIcon(let value):
            titleControl.icon = (value.size == .zero ? nil : value)
        case .headerTitle(let value):
            titleControl.titleLabelText = value
        case .headerSubtitle(let value):
            titleControl.subtitleLabelText = value
        case .inputUpdate(.update(let update)):
            replyControl.feed(update: update)
        case .inputUpdate(.fill(_, let attachments)):
            replyControl.updateAttachments(objects: attachments)
        case .inputUpdate(.updateAttachment(let attachment)):
            replyControl.updateAttachments(objects: [attachment])
        case .inputUpdate(.failedAttachments):
            replyControl.removeAttachments()
        case .inputUpdate(.shakeAttachments):
            replyControl.shakeAttachments()
        case .timelineScrollToBottom:
            scrollToBottom()
        case .discardAllAttachments:
            replyControl.removeAttachments()
        case .timelineRecreate:
            DispatchQueue.main.async { [weak self] in
                self?.recreateTableView()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = JVDesign.colors.resolve(usage: .primaryBackground)
        
        if Bundle.main.jv_ID == Bundle.identifier(preset: .rmo) {
            view.addSubview(copyrightControl)
        }
        
        placeholderView.view.isHidden = true
        placeholderView.view.layer.zPosition = 100
        view.addSubview(placeholderView.view)
        
        titleControl.icon = uiConfig.icon
        titleControl.titleLabelText = uiConfig.titleCaption
        titleControl.titleLabelTextColor = uiConfig.titleColor
        titleControl.subtitleLabelText = uiConfig.subtitleCaption
        titleControl.subtitleLabelTextColor = uiConfig.subtitleColor
        
        replyUnderlay.backgroundColor = JVDesign.colors.resolve(usage: .primaryBackground)
        replyUnderlay.accessibilityLabel = "replyUnderlay"
        view.addSubview(replyUnderlay)
        
        replyControl.tintColor = uiConfig.outcomingPalette?.inputTintColor
        replyControl.inputAccessoryView = keyboardObservingBar
        replyUnderlay.addSubview(replyControl)
        
        DispatchQueue.main.async { [weak self] in
            self?.pipeline.notify(intent: .didLoad)
            
            if let button = self?.replyControl.menuButton {
                self?.pipeline.notify(intent: .prepareAttachButton(button: button))
            }
        }
        
        replyControl.outputHandler = { [weak self] output in
            switch output {
            case .text(let value, _):
                self?.pipeline.notify(intent: .textDidChange(text: value))
            case .height:
                self?.view.setNeedsLayout()
            case .submit(let text):
                self?.pipeline.notify(intent: .sendMessage(text: text))
            case .tapAttachment:
                break
            case .discardAttachment(let index):
                self?.replyControl.removeAttachment(at: index)
                self?.pipeline.notify(intent: .attachmentDidDismiss(index: index))
            case .extra(.menuLongPress(let button)):
                self?.pipeline.notify(intent: .requestDeveloperMenu(anchor: button))
            }
        }
        
        keyboardObservingBar.keyboardFrameChangedBlock = { [weak self] visible, frame in
            self?.handleKeyboard(visible: visible, frame: frame)
        }
        
        timelineInteractor.requestMediaHandler = { [weak self] url, mime in
            guard let `self` = self else { return }
            self.pipeline.notify(intent: .mediaTap(url: url, mime: mime))
        }
        
        timelineInteractor.tapHandler = { [weak self] itemUUID, tap in
            guard let `self` = self else { return }
            self.pipeline.notify(intent: .messageTap(itemUUID: itemUUID, interaction: tap))
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let layout = getLayout(size: view.bounds.size)
        collectionView?.frame = layout.collectionViewFrame
        placeholderView.view.frame = layout.placeholderViewFrame
        replyUnderlay.frame = layout.replyUnderlayFrame
        replyControl.frame = layout.replyControlBounds
        titleControl.frame = layout.titleBarFrame
        copyrightControl.frame = layout.copyrightControlFrame
        
        if let collectionView = collectionView {
            let contentOffsetY = collectionView.contentOffset.y
            let contentInsetDelta = collectionView.contentInset.top - layout.collectionViewContentInsets.top
            collectionView.contentInset = layout.collectionViewContentInsets
            collectionView.contentOffset.y = max(-layout.collectionViewContentInsets.top, contentOffsetY + contentInsetDelta)
            collectionView.scrollIndicatorInsets = layout.collectionViewIndicatorInsets
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pipeline.notify(intent: .willAppear)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func getLayout(size: CGSize) -> Layout {
        Layout(
            bounds: CGRect(origin: .zero, size: size),
            safeAreaInsets: view.safeAreaInsets,
            navigationBarFrame: navigationController?.navigationBar.bounds ?? CGRect.zero,
            replyControl: replyControl,
            bottomGap: 6,
            keyboardHeight: keyboardHeight
        )
    }
    
    private func recreateTableView() {
        if let timelineView = collectionView as? JMTimelineView<ChatTimelineInteractor> {
            timelineController.detach(timelineView: timelineView)
        }
        
        let isHidden = collectionView?.isHidden ?? false
        collectionView?.removeFromSuperview()

        let cv = JMTimelineView(interactor: timelineInteractor)
        cv.alwaysBounceVertical = true
        cv.contentInsetAdjustmentBehavior = .never
        cv.isHidden = isHidden
        view.insertSubview(cv, at: 0)
//        view.insertSubview(historyPlaceholder, aboveSubview: cv)
        collectionView = cv

        timelineController.attach(timelineView: cv) { [weak self] event in
            self?.pipeline.notify(intent: .timelineEvent(event))
        }
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        tapGesture.delaysTouchesBegan = false
        tapGesture.addTarget(self, action: #selector(handleCollectionTap))
        tapGesture.delegate = timelineControlTapDelegate
        cv.addGestureRecognizer(tapGesture)
    }
    
    private func prepareLayoutAsLoading() {
        placeholderView.placeholderItems = Array()
        placeholderView.view.isHidden = false
        placeholderView.startWaiting()
    }
    
    private func prepareLayoutAsChatting() {
        placeholderView.view.isHidden = true
    }
    
    private func prepareLayoutAsUnavailable() {
        placeholderView.placeholderItems = [
            .init(
                content: .icon(
                    under: UIImage(named: "chat_unavailable_placeholder", in: Bundle(for: JVDesign.self), compatibleWith: nil),
                    over: nil
                ),
                gap: .auto
            ),
            .init(
                content: .title(loc["chat.state_unavailable.title"]),
                gap: .auto
            ),
            .init(
                content: .body(loc["chat.state_unavailable.discription"]),
                gap: .auto
            ),
        ]
        
        placeholderView.view.isHidden = false
        placeholderView.stopWaiting()
        
        replyControl.resignFirstResponder()
    }
    
    private func scrollToBottom() {
        guard
            let timelineView = collectionView as? JMTimelineView<ChatTimelineInteractor>,
            timelineView.jv_canScroll
        else {
            return
        }
        
        timelineView.jv_scrollToTop(duration: UIApplication.shared.jv_isActive ? 0.15 : 0)
    }
    
    private func handleKeyboard(visible: Bool, frame: CGRect) {
        let globalFrame = view.convert(view.bounds, to: view.window)
        let newKeyboardHeight = globalFrame.intersection(frame).height
        
        if keyboardHeight != newKeyboardHeight {
            keyboardHeight = newKeyboardHeight
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }

        
//        UIView.animate(withDuration: 0.25, animations: view.layoutIfNeeded)

//        if visible {
//            scrollToBottom()
//        }
    }

    @objc private func handleDismissButtonTap() {
        pipeline.notify(intent: .dismiss)
    }
    
    @objc private func handleCollectionTap() {
        view.endEditing(true)
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let safeAreaInsets: UIEdgeInsets
    let navigationBarFrame: CGRect
    let replyControl: SdkChatReplyControl
    let bottomGap: CGFloat
    let keyboardHeight: CGFloat

    private let copyrightHeight = CGFloat(30)
    
    var safeAreaFrame: CGRect {
        return bounds.jv_reduceBy(insets: safeAreaInsets)
    }
    
    var titleBarFrame: CGRect {
        return CGRect(origin: CGPoint.zero, size: CGSize(width: navigationBarFrame.width, height: navigationBarFrame.height))
    }
    
    var placeholderViewFrame: CGRect {
        return safeAreaFrame
    }
    
    var collectionViewFrame: CGRect {
        return bounds
    }
    
    var collectionViewContentInsets: UIEdgeInsets {
        let headerHeight = (Bundle.main.jv_ID == Bundle.identifier(preset: .rmo) ? copyrightHeight : 0)
        let replyingHeight = max(safeAreaInsets.bottom, keyboardHeight) + replyControlBounds.height + bottomGap
        return UIEdgeInsets(top: replyingHeight, left: 0, bottom: headerHeight, right: 0)
    }
    
    var collectionViewIndicatorInsets: UIEdgeInsets {
        let replyingHeight = max(safeAreaInsets.bottom, keyboardHeight) + replyControlBounds.height
        return UIEdgeInsets(top: replyingHeight, left: 0, bottom: 0, right: 0)
    }
    
    var replyUnderlayFrame: CGRect {
        let anchor = replyControlBounds
        let topY = bounds.height - max(safeAreaInsets.bottom, keyboardHeight) - anchor.height
        let workaroundGap = CGFloat(5)
        let height = anchor.height + safeAreaInsets.bottom + workaroundGap
        return CGRect(x: 0, y: topY, width: bounds.width, height: height)
    }
    
    var replyControlBounds: CGRect {
        let height = replyControl.jv_height(forWidth: bounds.width)
        return CGRect(x: 0, y: 0, width: bounds.width, height: height)
    }
    
    var copyrightControlSize: CGSize {
        return CGSize(width: bounds.width, height: copyrightHeight)
    }
    
    var copyrightControlFrame: CGRect {
        let origin = CGPoint(x: .zero, y: collectionViewFrame.minY)
        return CGRect(origin: origin, size: copyrightControlSize)
    }
}

fileprivate final class TimelineControlTapDelegate: NSObject, UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive event: UIEvent) -> Bool {
        guard let view = gestureRecognizer.view,
              let touch = event.allTouches?.first
        else {
            return true
        }
        
        let point = touch.location(in: view)
        let control = view.hitTest(point, with: event)
        
        if control is UIControl {
            gestureRecognizer.isEnabled = false
            gestureRecognizer.isEnabled = true
            return false
        }
        else {
            return true
        }
    }
}

fileprivate extension CGFloat {
    var debug: String {
        return "\(Int(self))"
    }
}

fileprivate extension CGRect {
    var debug: String {
        return "(x=\(Int(origin.x)) y=\(Int(origin.y)) w=\(Int(size.width)) h=\(Int(size.height)))"
    }
}
