//
//  SdkEngineBridges.swift
//  JivoSDK
//
//  Created by Stan Potemkin on 16.08.2022.
//

import Foundation

struct SdkEngineBridges {
    let popupPresenterBridge: IPopupPresenterBridge
    let photoPickingBridge: IPhotoPickingBridge
    let documentsBridge: IDocumentsBridge
    let webBrowsingBridge: IWebBrowsingBridge
    let emailComposingBridge: IEmailComposingBridge
    let keyboardListenerBridge: IKeyboardListenerBridge
}

struct SdkEngineBridgesFactory {
    let photoLibraryDriver: IPhotoLibraryDriver
    let cameraDriver: ICameraDriver
    
    func build() -> SdkEngineBridges {
        let popupPresenterBridge = buildPopupPresenterBridge()
        
        return SdkEngineBridges(
            popupPresenterBridge: popupPresenterBridge,
            photoPickingBridge: buildPhotoPickingBridge(
                popupPresenterBridge: popupPresenterBridge),
            documentsBridge: buildDocumentsBridge(),
            webBrowsingBridge: buildWebBrowsingBridge(),
            emailComposingBridge: buildEmailComposingBridge(),
            keyboardListenerBridge: buildKeyboardListenerBridge()
        )
    }
    
    private func buildPopupPresenterBridge() -> IPopupPresenterBridge {
        return PopupPresenterBridge()
    }
    
    private func buildPhotoPickingBridge(popupPresenterBridge: IPopupPresenterBridge) -> IPhotoPickingBridge {
        return PhotoPickingBridge(
            popupPresenterBridge: popupPresenterBridge,
            photoLibraryDriver: photoLibraryDriver,
            cameraDriver: cameraDriver)
    }
    
    private func buildDocumentsBridge() -> IDocumentsBridge {
        return DocumentsBridge()
    }
    
    private func buildWebBrowsingBridge() -> IWebBrowsingBridge {
        return WebBrowsingBridge()
    }
    
    private func buildEmailComposingBridge() -> IEmailComposingBridge {
        return EmailComposingBridge()
    }
    
    private func buildKeyboardListenerBridge() -> IKeyboardListenerBridge {
        return KeyboardListenerBridge()
    }
}
