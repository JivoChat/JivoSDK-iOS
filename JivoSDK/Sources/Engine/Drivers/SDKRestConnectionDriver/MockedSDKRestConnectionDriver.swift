//
//  MockedSDKRestConnectionDriver.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 05.12.2021.
//  Copyright © 2021 jivosite.mobile. All rights reserved.
//

import Foundation
import JMCodingKit

struct RestMockedResponse {
    let delay: TimeInterval
    let result: RestConnectionResult
}

protocol RestMockedResponseRule {
    func respond(to requestURL: URL) -> RestMockedResponse?
}

class PushesRegisterRequestMockedResponseRule {
    private let REGEX_PATTERN = "https:\\/\\/node\\.?\\w*\\.?\\w*\\.jivosite\\.com:?\\d*\\/client\\/\\d+\\/\\w+\\/device"
    
    var responseProvider: (URL) -> RestConnectionResult
    
    private let regex: NSRegularExpression?
    
    init(responseProvider: @escaping (URL) -> RestConnectionResult) {
        self.responseProvider = responseProvider
        
        do {
            regex = try NSRegularExpression(pattern: REGEX_PATTERN, options: .caseInsensitive)
        } catch {
            journal {"Failed creating PushesRegisterRequestMockedResponseRule error[\(error.localizedDescription)]"}
            regex = nil
        }
    }
}

extension PushesRegisterRequestMockedResponseRule: RestMockedResponseRule {
    func respond(to requestURL: URL) -> RestMockedResponse? {
        let source = requestURL.absoluteString
        let range = NSRange(location: 0, length: source.utf16.count)
        
        guard let _ = regex?.firstMatch(in: source, options: [], range: range) else { return nil }
        let result = responseProvider(requestURL)
        return RestMockedResponse(delay: 0.5, result: result)
    }
}

class MockedSDKRestConnectionDriver: IRestConnectionDriver {
    var failureCallback: ((HTTPURLResponse, TimeInterval?) -> Void)?
    
    private let responseRules: [RestMockedResponseRule]
    
    private let urlSession: URLSession
    private let coder = JsonCoder()
    private var activeMutex = NSLock()
    private var activeRequests: [URL: RepeatingRequest]
    
    init(responseRules: [RestMockedResponseRule]) {
        self.responseRules = responseRules
        
        urlSession = URLSession(configuration: makePrimarySessionConfig())
        activeRequests = Dictionary()
    }
    
    func request(url: URL, options: RestRequestOptions, networkingHelper: INetworkingHelper, callback: ((RestConnectionResult) -> Void)?) {
//        let query = options.query
//            .reduce(JsonElement()) { buffer, item in buffer.merged(with: item) }
//            .dictObject
//            .map { item in URLQueryItem(name: item.key, value: String(describing: item.value)) }
        
        let operation = RepeatingRequest(repeatsCountLimit: 3) { [weak self] repeatingRequest in
            if let mockedResponse = self?.responseRules.compactMap({ $0.respond(to: url) }).first {
                DispatchQueue.main.asyncAfter(deadline: .now() + mockedResponse.delay) {
                    self?.activeMutex.lock()
                    self?.activeRequests.removeValue(forKey: url)
                    self?.activeMutex.unlock()
                    
                    callback?(mockedResponse.result)
                }
            }
        }
        
        activeMutex.lock()
        activeRequests[url] = operation
        activeMutex.unlock()
        
        operation.perform()
    }
    
    func upload(file: HTTPFileConfig, config: HTTPFileUploadConfig, callback: @escaping (HTTPUploadAck) -> Void) {
    }
    
    func upload(media: HTTPFileConfig, config: HTTPMediaUploadConfig, callback: @escaping (HTTPUploadAck) -> Void) {
    }
    
    func cancelActiveRequests() {
    }
    
    func cancelBackgroundRequests() {
    }
    
    private func handleRestRequestCompletion(
        url: URL,
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) -> RestRequestResult {
        // A stub for compilability
        return RestRequestResult(
            url: URL(string: "")!,
            status: .badRequest,
            body: JsonElement.null
        )
    }
    
    private func stringHeaders(for anyTypeHeaders: [AnyHashable: Any]) -> [String: String] {
        let convertedHeaders = Dictionary<String, String>(
            uniqueKeysWithValues: anyTypeHeaders
                .compactMap { header in
                    guard
                        let key = header.0 as? String,
                        let value = header.1 as? String
                    else { return nil }
                    return (key: key, value: value)
                }
        )
        return convertedHeaders
    }
}

fileprivate func makePrimarySessionConfig() -> URLSessionConfiguration {
    if let config = URLSessionConfiguration.default.copy() as? URLSessionConfiguration {
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 20
        config.networkServiceType = .responsiveData
        return config
    }
    else {
        return URLSessionConfiguration.default
    }
}

fileprivate extension URLComponents {
    var query: [URLQueryItem] {
        get { queryItems ?? Array() }
        set { queryItems = newValue }
    }
}

