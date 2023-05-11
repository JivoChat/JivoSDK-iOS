//
//  NetworkingSubRest.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 03.08.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

final class NetworkingSubRest: INetworkingSubRest {
    private let networkingHelper: INetworkingHelper
    private let driver: IRestConnectionDriver
    
    init(networkingHelper: INetworkingHelper, driver: IRestConnectionDriver) {
        self.networkingHelper = networkingHelper
        self.driver = driver
    }
    
    let eventObservable = JVBroadcastTool<NetworkingSubRestEvent>()
    
    func request(requestID: UUID?, url: URL, options: RestRequestOptions) {
        driver.request(
            url: url,
            options: options,
            networkingHelper: networkingHelper,
            callback: { result in
                guard let requestID = requestID else {
                    return
                }
                
                let event = NetworkingSubRestEvent.response(
                    requestID,
                    result.url,
                    .init(status: result.status, body: result.body)
                )
                
                self.eventObservable.broadcast(event)
            }
        )
    }
    
    func upload(file: HTTPFileConfig, config: HTTPFileUploadConfig, callback: @escaping (HTTPUploadAck) -> Void) {
        driver.upload(
            file: file,
            config: config,
            callback: callback)
    }

    func upload(media: HTTPFileConfig, config: HTTPMediaUploadConfig, callback: @escaping (HTTPUploadAck) -> Void) {
        driver.upload(
            media: media,
            config: config,
            callback: callback)
    }

    func cancelActiveRequests() {
        driver.cancelActiveRequests()
    }
    
    func cancelBackgroundRequests() {
        driver.cancelBackgroundRequests()
    }
}
