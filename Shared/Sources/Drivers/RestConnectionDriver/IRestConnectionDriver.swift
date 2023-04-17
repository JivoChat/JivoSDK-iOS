//
//  RestConnectionDriver.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 04/05/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit
import SwiftGraylog

protocol IRestConnectionDriver: AnyObject {
    var failureCallback: ((HTTPURLResponse, TimeInterval?) -> Void)? { get set }
    func request(url: URL, options: RestRequestOptions, networkingHelper: INetworkingHelper, callback: ((RestConnectionResult) -> Void)?)
    func upload(file: HTTPFileConfig, config: HTTPFileUploadConfig, callback: @escaping (HTTPUploadAck) -> Void)
    func upload(media: HTTPFileConfig, config: HTTPMediaUploadConfig, callback: @escaping (HTTPUploadAck) -> Void)
    func cancelActiveRequests()
    func cancelBackgroundRequests()
}
