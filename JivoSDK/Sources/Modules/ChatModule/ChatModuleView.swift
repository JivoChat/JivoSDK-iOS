//  
//  ChatModuleView.swift
//  Pods
//
//  Created by Stan Potemkin on 11.08.2022.
//

import Foundation
import UIKit
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
    case specialMenu
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
    init(
        pipeline: RTEModulePipelineViewNotifier<ChatModuleViewIntent>,
        keyboardAnchorControl: KeyboardAnchorControl,
        timelineController: JMTimelineController<ChatHistoryConfig, ChatTimelineInteractor>,
        timelineInteractor: ChatTimelineInteractor,
        timelineLoaderItem: JMTimelineItem,
        uiConfig: SdkChatModuleVisualConfig,
        closeButton: JVDisplayCloseButton
    ) {
        super.init(
            primaryView: ChatModuleViewController(
                pipeline: pipeline,
                keyboardAnchorControl: keyboardAnchorControl,
                timelineController: timelineController,
                timelineInteractor: timelineInteractor,
                timelineLoaderItem: timelineLoaderItem,
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
    private lazy var waitingIndicator = UIView()
    private lazy var replyUnderlay = UIView()
    private lazy var replyControl = SdkChatReplyControl()
    
    private let keyboardAnchorControl: KeyboardAnchorControl
    private let timelineController: JMTimelineController<ChatHistoryConfig, ChatTimelineInteractor>
    private let timelineInteractor: ChatTimelineInteractor
    private let timelineLoaderItem: JMTimelineItem
    private let uiConfig: SdkChatModuleVisualConfig
    
    private let placeholderView = PlaceholderViewController<SdkEngine>(satellite: nil, layout: .center)
    private(set) var collectionView: UICollectionView?
    private var keyboardHeight = CGFloat(0)
    
    private let timelineControlTapDelegate = TimelineControlTapDelegate()

    init(
        pipeline: RTEModulePipelineViewNotifier<ChatModuleViewIntent>,
        keyboardAnchorControl: KeyboardAnchorControl,
        timelineController: JMTimelineController<ChatHistoryConfig, ChatTimelineInteractor>,
        timelineInteractor: ChatTimelineInteractor,
        timelineLoaderItem: JMTimelineItem,
        uiConfig: SdkChatModuleVisualConfig,
        closeButton: JVDisplayCloseButton
    ) {
        self.keyboardAnchorControl = keyboardAnchorControl
        self.timelineController = timelineController
        self.timelineInteractor = timelineInteractor
        self.timelineLoaderItem = timelineLoaderItem
        self.uiConfig = uiConfig
        
        super.init(pipeline: pipeline)
        
        navigationItem.titleView = titleControl
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: makeInfoLabel())
        
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
    
    private func makeInfoLabel() -> UIView {
        let label = UILabel()
        label.text = "ver " + Bundle(for: Jivo.self).jv_formatVersion(.marketingShort)
        label.textColor = JVDesign.colors.resolve(usage: .unnoticeableForeground)
        label.font = JVDesign.fonts.resolve(.semibold(12), scaling: .caption2)
        label.isUserInteractionEnabled = true
        label.sizeToFit()

        label.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(handleInfoLabelLongPress))
        )
        
        return label
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
        case .startSyncing:
            waitingIndicator.jv_startShimming()
        case .stopSyncing:
            waitingIndicator.jv_stopShimming()
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
        case .timelineFailure:
            journal {"UI: Timeline update faced an exception"}
            DispatchQueue.main.async { [weak self] in
                self?.recreateTableView()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = JVDesign.colors.resolve(usage: .primaryBackground)
        
        placeholderView.view.isHidden = true
        placeholderView.view.layer.zPosition = 100
        view.addSubview(placeholderView.view)
        
        titleControl.icon = uiConfig.icon
        titleControl.titleLabelText = uiConfig.titleCaption
        titleControl.titleLabelTextColor = uiConfig.titleColor
        titleControl.subtitleLabelText = uiConfig.subtitleCaption
        titleControl.subtitleLabelTextColor = uiConfig.subtitleColor
        
        waitingIndicator.backgroundColor = JVDesign.colors.resolve(usage: .primaryForeground).withAlphaComponent(0.4)
        waitingIndicator.alpha = 0
        view.addSubview(waitingIndicator)
        
        replyUnderlay.backgroundColor = JVDesign.colors.resolve(usage: .primaryBackground)
        replyUnderlay.accessibilityLabel = "replyUnderlay"
        view.addSubview(replyUnderlay)
        
        replyControl.tintColor = uiConfig.replyCursorColor
        replyControl.inputAccessoryView = keyboardAnchorControl
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
        
        keyboardAnchorControl.keyboardFrameChangedBlock = { [weak self] visible, frame in
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
        waitingIndicator.frame = layout.waitingIndicatorFrame
        replyUnderlay.frame = layout.replyUnderlayFrame
        replyControl.frame = layout.replyControlBounds
        titleControl.frame = layout.titleBarFrame
        
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
                content: .title(loc["JV_ChatScreen_PlaceholderUnavailable_Headline", "chat.state_unavailable.title"]),
                gap: .auto
            ),
            .init(
                content: .body(loc["JV_ChatScreen_PlaceholderUnavailable_Body", "chat.state_unavailable.discription"]),
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
        
        timelineView.jv_scrollToTop(duration: UIApplication.shared.applicationState.jv_isOnscreen ? 0.15 : 0)
    }
    
    private func handleKeyboard(visible: Bool, frame: CGRect) {
        let globalFrame = view.convert(view.bounds, to: view.window)
        let newKeyboardHeight = globalFrame.intersection(frame).height
        
        if keyboardHeight != newKeyboardHeight {
            keyboardHeight = newKeyboardHeight
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }

    @objc private func handleDismissButtonTap() {
        pipeline.notify(intent: .dismiss)
    }
    
    @objc private func handleCollectionTap() {
        view.endEditing(true)
    }
    
    @objc private func handleInfoLabelLongPress() {
        pipeline.notify(intent: .specialMenu)
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let safeAreaInsets: UIEdgeInsets
    let navigationBarFrame: CGRect
    let replyControl: SdkChatReplyControl
    let bottomGap: CGFloat
    let keyboardHeight: CGFloat

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
        let replyingHeight = max(safeAreaInsets.bottom, keyboardHeight) + replyControlBounds.height + bottomGap
        return UIEdgeInsets(top: replyingHeight, left: 0, bottom: 0, right: 0)
    }
    
    var collectionViewIndicatorInsets: UIEdgeInsets {
        let replyingHeight = max(safeAreaInsets.bottom, keyboardHeight) + replyControlBounds.height
        return UIEdgeInsets(top: replyingHeight, left: 0, bottom: 0, right: 0)
    }
    
    var waitingIndicatorFrame: CGRect {
        let height = CGFloat(2)
        let topY = replyUnderlayFrame.minY - 1 - height
        let width = bounds.width * 0.5
        let leftX = (bounds.width - width) * 0.5
        return CGRect(x: leftX, y: topY, width: width, height: height)
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
