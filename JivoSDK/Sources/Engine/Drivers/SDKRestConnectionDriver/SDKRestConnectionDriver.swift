//
//  SDKRestConnectionDriver.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 05.08.2021.
//

import Foundation
import JMCodingKit

struct RestRequestResult {
    let url: URL
    let status: RestResponseStatus
    let body: JsonElement
}

class SDKRestConnectionDriver: IRestConnectionDriver {
    var failureCallback: ((HTTPURLResponse, TimeInterval?) -> Void)?
    
    private let urlSession: URLSession
    private let coder = JsonCoder()
    private var activeMutex = NSLock()
    private var activeRequests: [URL: RepeatingRequest]
    
    init() {
        urlSession = URLSession(configuration: makePrimarySessionConfig())
        activeRequests = Dictionary()
    }
    
    func request(url: URL, options: RestRequestOptions, networkingHelper: INetworkingHelper, callback: ((RestConnectionResult) -> Void)?) {
        let query = options.query
            .reduce(JsonElement()) { buffer, item in
                buffer.merged(with: item)
            }
            .dictObject
            .flatMap { key, object in
                (key, String(describing: object))
            }
        
        let components: URLComponents = {
            var c = URLComponents(string: url.absoluteString) ?? URLComponents()
            c.scheme = "https"
            c.jv_setQuery(mapping: Dictionary(uniqueKeysWithValues: query))
            return c
        }()
        
        guard let url = components.url else {
            journal {"Failed generating the URL object from components[\(components)]"}
            return
        }
        
        let request: URLRequest = {
            var req = URLRequest(url: url)
            req.httpMethod = options.method.rawValue
            
            for header in networkingHelper.generateHeaders(auth: .omit, requestId: .auto, contentType: nil) {
                req.setValue(header.value, forHTTPHeaderField: header.key)
            }
            
            for header in options.headers {
                req.setValue(header.value, forHTTPHeaderField: header.key)
            }
            
            do {
                switch options.body {
                case .omit:
                    req.httpBody = nil
                case .simple(.object(let object)):
                    req.httpBody = object.dictObject
                        .map { item in
                            let value = String(describing: item.value)
                            return "\(item.key)=\(value.jv_escape() ?? value)"
                        }
                        .joined(separator: "&")
                        .data(using: .utf8)
                case .simple(.params(let params)):
                    let object = params.reduce(JsonElement()) { buffer, item in buffer.merged(with: item) }
                    req.httpBody = object.dictObject
                        .map { item in
                            let value = String(describing: item.value)
                            return "\(item.key)=\(value.jv_escape() ?? value)"
                        }
                        .joined(separator: "&")
                        .data(using: .utf8)
                case .json(.object(let object)):
                    if JSONSerialization.isValidJSONObject(object.dictObject) {
                        req.httpBody = try JSONSerialization.data(withJSONObject: object.dictObject)
                    } else {
                        journal {"Cannot serialize JsonElement into Data: the object is not a valid JSON"}
                    }
                case .json(.params(let params)):
                    let object = params
                        .reduce(JsonElement()) { buffer, item in buffer.merged(with: item) }
                        .dictObject
                    if JSONSerialization.isValidJSONObject(object) {
                        req.httpBody = try JSONSerialization.data(withJSONObject: object)
                    } else {
                        journal {"Cannot serialize JsonElement into Data: the object is not a valid JSON"}
                    }
                }
            }
            catch {
            }
            
            if let body = req.httpBody {
                req.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
            }

            return req
        }()

        let operation = RepeatingRequest(repeatsCountLimit: 3) { [unowned self, coder = coder] repeatingRequest in
            let task = self.urlSession.dataTask(with: request) { data, response, error in
                self.activeMutex.lock()
                self.activeRequests.removeValue(forKey: url)
                self.activeMutex.unlock()
                
                guard
                    let data = data,
                    let httpResponse = response as? HTTPURLResponse,
                    let url = httpResponse.url
                else {
                    return
                }
                
                let status = RestResponseStatus(rawValue: httpResponse.statusCode) ?? .unknown(httpResponse.statusCode)
                let json = coder.decode(binary: data, encoding: .utf8) ?? .null
                
                DispatchQueue.main.async { [unowned self] in
                    let result = RestConnectionResult(
                        url: url,
                        status: status,
                        headers: stringHeaders(for: httpResponse.allHeaderFields),
                        body: json
                    )
                    callback?(result)
                }
            }
            
            task.resume()
        }
        
        journal {"Requesting the REST path[\(request.url?.lastPathComponent ?? String())]"}
        
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
