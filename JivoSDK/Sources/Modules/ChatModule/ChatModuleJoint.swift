//  
//  ChatModuleJoint.swift
//  Pods
//
//  Created by Stan Potemkin on 11.08.2022.
//

import Foundation
import PhotosUI
import MobileCoreServices

enum ChatModuleJointInput {
    case pickDocument(url: URL)
    case pickImage(UIImage)
    case documentsLimitExceeded
    case performMessageCopy
    case performMessageResend
    case requestDeveloperLogs
}

enum ChatModuleJointOutput {
    case dismiss
    case started
    case finished
}

final class ChatModuleJoint
: RTEModuleJoint<
    ChatModulePipeline,
    ChatModuleJointOutput,
    ChatModuleJointInput,
    ChatModuleCoreEvent,
    ChatModuleViewIntent,
    ChatModuleState
> {
    private let uiConfig: ChatModuleUIConfig
    private let typingCacheService: ITypingCacheService
    private let popupPresenterBridge: IPopupPresenterBridge
    private let photoPickingBridge: IPhotoPickingBridge
    private let documentsBridge: IDocumentsBridge
    private let webBrowsingBridge: IWebBrowsingBridge
    private let emailComposingBridge: IEmailComposingBridge
    private let photoLibraryDriver: IPhotoLibraryDriver
    private let cameraDriver: ICameraDriver
    
    private var imagePickerModule: ImagePickerModuleProtocol?
    private var imageLoadingQueue: DispatchQueue?
    private var mailComposeModule: MailComposeModule?
    private var browserPresentingViewController: UIViewController?
    
    init(pipeline: ChatModulePipeline, state: ChatModuleState, view: UIViewController, navigator: IRTNavigator, uiConfig: ChatModuleUIConfig, typingCacheService: ITypingCacheService, popupPresenterBridge: IPopupPresenterBridge, photoPickingBridge: IPhotoPickingBridge, documentsBridge: IDocumentsBridge, webBrowsingBridge: IWebBrowsingBridge, emailComposingBridge: IEmailComposingBridge, photoLibraryDriver: IPhotoLibraryDriver, cameraDriver: ICameraDriver) {
        self.uiConfig = uiConfig
        self.typingCacheService = typingCacheService
        self.popupPresenterBridge = popupPresenterBridge
        self.photoPickingBridge = photoPickingBridge
        self.documentsBridge = documentsBridge
        self.webBrowsingBridge = webBrowsingBridge
        self.emailComposingBridge = emailComposingBridge
        self.photoLibraryDriver = photoLibraryDriver
        self.cameraDriver = cameraDriver
        
        super.init(pipeline: pipeline, state: state, view: view, navigator: navigator)
    }
    
    deinit {
        notifyOut(output: .finished)
    }
    
    override func handleCore(event: ChatModuleCoreEvent) {
        switch event {
        case .warnAbout(let message):
            presentWarning(message: message)
        case .journalReady(let url, let data):
            presentJournalSending(url: url, data: data)
        case .mediaUploadFailure(let error):
            presentMediaUploadFailure(error: error)
        default:
            break
        }
    }
    
    override func handleView(intent: ChatModuleViewIntent) {
        switch intent {
        case .didLoad:
            notifyOut(output: .started)
        case .mediaTap(let url, let mime):
            presentBrowser(url: url, mime: mime)
        case .prepareAttachButton(let button):
            setupAttachmentMenu(anchor: button)
        case .requestDeveloperMenu(let anchor):
            presentDeveloperMenu(anchor: anchor)
        case .dismiss where view?.navigationController?.viewControllers.first === view:
            view?.dismiss(animated: true)
            notifyOut(output: .dismiss)
        case .dismiss:
            view?.navigationController?.popViewController(animated: true)
            notifyOut(output: .dismiss)
        default:
            break
        }
    }
    
    private func presentWarning(message: String) {
        popupPresenterBridge.displayAlert(
            within: .specific(view),
            title: nil,
            message: message,
            items: [
                .dismiss(.close)
            ])
    }
    
    private func presentJournalSending(url: URL, data: Data) {
        guard let view = view
        else {
            return
        }
        
        let config = EmailComposingConfig(
            to: ["ios-support@jivosite.com"],
            subject: "JivoSDK[iOS] Debugging Logs",
            body: String(),
            attachments: [
                .init(data: data, mime: "application/zip", name: url.lastPathComponent)
            ]
        )
        
        self.emailComposingBridge.presentComposer(within: view, config: config) { [weak self] output in
            let outputToMessageMap: [EmailComposingOutput: String] = [
                .unavailable: "This device is not configured to send emails",
                .cancelled: "Mail sending cancelled",
                .drafted: "Mail sending failed",
                .sent: "Logs successfully sent",
                .failed: "Your draft was saved"
            ]
            
            self?.popupPresenterBridge.displayAlert(
                within: .specific(view),
                title: nil,
                message: outputToMessageMap[output] ?? "Something went wrong",
                items: [
                    .dismiss(.close)
                ])
        }
    }
    
    private func presentMediaUploadFailure(error: MediaUploadError) {
        let message: String = {
            switch error {
            case .extractionFailed:
                return loc["media_uploading_extraction_error"]
            case .fileSizeExceeded(let megabytes):
                return loc[format: "media_uploading_too_large", megabytes]
            case .networkClientError, .cannotHandleUploadResult:
                journal {"Failed uploading"}
                    .nextLine {"Failed to upload the file"}
                
                return loc["media_uploading_common_error"]
            case let .uploadDeniedByAServer(brief):
                journal {"Failed uploading"}
                    .nextLine {"Failed to upload the file"}
                
                return brief ?? loc["media_uploading_common_error"]
            case .unsupportedMediaType:
                return loc["message_unsupported_media"]
            case let .unknown(brief):
                journal {"Failed uploading"}
                    .nextLine {"Failed to upload the file"}
                
                return brief ?? loc["media_uploading_common_error"]
            }
        }()
        
        popupPresenterBridge.displayAlert(
            within: .specific(view),
            title: nil,
            message: message,
            items: [
                .dismiss(.close)
            ])
    }
    
    private func setupAttachmentMenu(anchor: UIButton) {
        guard typingCacheService.canAttachMore
        else {
            pipeline?.notify(input: .documentsLimitExceeded)
            return
        }
        
        let extraItems: [PopupPresenterItem] = uiConfig.replyMenuExtraItems.enumerated().map { index, title in
                .action(title, .noicon, .regular { [weak self] _ in
                    self?.uiConfig.replyMenuCustomHandler(index)
                })
        }
        
        popupPresenterBridge.attachMenu(
            to: anchor,
            location: .bottom,
            items: [
                .action(uiConfig.attachLibrary, .icon(.photo), .regular { [weak self] _ in
                    self?.presentMediaPicker(source: .library)
                }),
                .action(uiConfig.attachCamera, .icon(.camera), .regular { [weak self] _ in
                    self?.presentMediaPicker(source: .camera)
                }),
                .action(uiConfig.attachFile, .icon(.file), .regular { [weak self] _ in
                    self?.presentDocumentPicker()
                }),
                .children(items: extraItems)
            ]
        )
    }
    
    private func presentMediaPicker(source: PhotoPickingBridgeSource) {
        guard let view = view
        else {
            return
        }
        
        view.view.endEditing(false)
        photoPickingBridge.presentPicker(within: view, source: source) { [weak self] result in
            switch result {
            case .success(let medias):
                switch medias.first {
                case .image(let image):
                    self?.pipeline?.notify(input: .pickImage(image))
                case .video(let url):
                    self?.pipeline?.notify(input: .pickDocument(url: url))
                case .none:
                    return
                }
                
            case .failure:
                self?.popupPresenterBridge.displayAlert(
                    within: .root,
                    title: loc["common_unknown_error"],
                    message: loc["media_uploading_extraction_error"],
                    items: [
                        .dismiss(.close)
                    ])
            }
        }
    }
    
    private func presentDocumentPicker() {
        guard let viewController = view else { return }
        
        viewController.view.endEditing(false)
        documentsBridge.presentPicker(within: viewController) { [weak self] event in
            guard case .documents(let urls) = event,
                  let primaryUrl = urls.first
            else {
                return
            }
                    
            guard let fileSize = primaryUrl.jv_fileSize,
                  fileSize < SdkConfig.uploadingLimit.bytes
            else {
                self?.popupPresenterBridge.displayAlert(
                    within: .root,
                    title: loc["media_uploading_extraction_error"],
                    message: loc[format: "media_uploading_too_large", SdkConfig.uploadingLimit.megabytes],
                    items: [
                        .dismiss(.close)
                    ])
                
                return
            }
            
            self?.pipeline?.notify(input: .pickDocument(url: primaryUrl))
        }
    }
    
    private func presentBrowser(url: URL, mime: String?) {
        guard let view = view else { return }
        
        view.view.endEditing(false)
        webBrowsingBridge.presentBrowser(within: view, url: url, mime: mime)
    }
    
    private func presentDeveloperMenu(anchor: UIView) {
        popupPresenterBridge.displayMenu(
            within: .specific(view),
            anchor: anchor,
            title: "Developer Menu",
            message: nil,
            items: [
                .action("Send logs to Jivo developers", .noicon, .regular { [weak self] _ in
                    self?.pipeline?.notify(input: .requestDeveloperLogs)
                }),
                .dismiss(.cancel)
            ])
    }
    
    private func presentMessageMenu() {
        let optionsNeeded: [ContextMenuOptionType]
        if let meta = state.selectedMessageMeta {
            switch (meta.sender, meta.deliveryStatus) {
            case (.client, .failed):
                optionsNeeded = [.copy, .resendMessage]
            default:
                optionsNeeded = [.copy]
            }
        }
        else {
            optionsNeeded = [.copy]
        }
        
        popupPresenterBridge.displayMenu(
            within: .specific(view),
            anchor: nil,
            title: nil,
            message: nil,
            items: [.dismiss(.cancel)] + optionsNeeded.map { option in
                switch option {
                case .copy:
                    return .action(loc["options_copy"], .icon(.copy), .regular { [weak self] _ in
                        self?.pipeline?.notify(input: .performMessageCopy)
                    })
                case .resendMessage:
                    return .action(loc["options_resend"], .icon(.again), .regular { [weak self] _ in
                        self?.pipeline?.notify(input: .performMessageResend)
                    })
                }
            })
    }
}
