//
//  ErrorRendererConfiguration.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 28.02.2022.
//  Copyright © 2022 jivosite.mobile. All rights reserved.
//

import UIKit

fileprivate final class BundleObject {
}

struct ErrorRendererConfiguration {
    let image: UIImage?
    let errorDescriptionProvider: (RemoteStorageResourceRetrievingError) -> String
    let style: ErrorRenderer.Style
    
    init(
        image: UIImage? = nil,
        errorDescriptionProvider: @escaping (RemoteStorageResourceRetrievingError) -> String,
        style: ErrorRenderer.Style
    ) {
        self.image = image
        self.errorDescriptionProvider = errorDescriptionProvider
        self.style = style
    }
}

extension ErrorRendererConfiguration {
    static var forObsoleteImageLink: Self {
        return Self(
            image: UIImage.jv_named("unavailable_image_stub"),
            errorDescriptionProvider: { error in
                switch error {
                case .notFound:
                    return loc["JV_FileAttachment_LinkStatus_Expired", "file_download_expired"]
                default:
                    return loc["JV_FileAttachment_LinkStatus_Unavailable", "file_download_unavailable"]
                }
            },
            style: ErrorRenderer.Style(
                backgroundColor: JVDesign.colors.resolve(usage: .photoLoadingErrorStubBackground),
                iconScale: 1.0,
                errorDescriptionColor: JVDesign.colors.resolve(usage: .photoLoadingErrorDescription)
            )
        )
    }
    
    static var forUnavailableImage: Self {
        return Self(
            image: UIImage.jv_named("broken_image")?.withRenderingMode(.alwaysTemplate),
            errorDescriptionProvider: { error in
                switch error {
                default: return loc["Message.Instagram.NotAvailable"]
                }
            },
            style: ErrorRenderer.Style(
                backgroundColor: .clear,
                iconScale: 2.0,
                errorDescriptionColor: JVDesign.colors.resolve(usage: .secondaryForeground)
            )
        )
    }
}
