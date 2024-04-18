//
//  RestConnectionTypes.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 27/09/2017.
//  Copyright © 2017 JivoSite. All rights reserved.
//

import Foundation
import JMCodingKit

enum RestRequestMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
    case head = "HEAD"
}

enum RestResponseStatus: Codable {
    case success
    case badRequest
    case unauthorized
    case noAccess
    case notFound
    case conflict
    case maintenance
    case internalServerError
    case unknown(Int)
}

extension RestResponseStatus {
    var shouldRepeat: Bool {
        switch self {
        case .noAccess: return true
        default: return false
        }
    }
    
    var hookSucceed: Bool {
        switch self {
        case .success: return true
        case .badRequest: return true
        case .notFound: return true
        case .conflict: return true
        default: return false
        }
    }
}

extension RestResponseStatus: RawRepresentable {
    init?(rawValue: Int) {
        switch rawValue {
        case 200: self = .success
        case 400: self = .badRequest
        case 401: self = .unauthorized
        case 403: self = .noAccess
        case 404: self = .notFound
        case 409: self = .conflict
        case 480: self = .maintenance
        case 500: self = .internalServerError
        default: self = .unknown(rawValue)
        }
    }
    
    var rawValue: Int {
        switch self {
        case .success: return 200
        case .badRequest: return 400
        case .unauthorized: return 401
        case .noAccess: return 403
        case .notFound: return 404
        case .conflict: return 409
        case .maintenance: return 480
        case .internalServerError: return 500
        case let .unknown(statusCode): return statusCode
        }
    }
}

enum RestResponseFailure: String {
    case outOfLimit
    case unknownToken
}

struct HTTPResponseStatus {
    enum Failure: Error {
        case emailNotFound
        case passwordInvalid
        case tokenInvalid
        case accessDenied
        case accountBlocked
        case codeInvalid
        case calleeEqualsCaller
        case callExists
        case unavailableForCountry
        case newEqualsOld
        case technicalError
        case temporaryUnavailable
        case mfaRequired
        case unknown
        case badRequest
    }

    enum Warning: Error {
        case unknown
    }

    typealias Violation = String

    let hasAnswer: Bool
    let isOK: Bool
    let errorList: [Failure]
    let warningList: [Warning]
    let violationList: [Violation]
    
    init(ok: Bool = false) {
        hasAnswer = ok
        isOK = ok
        errorList = []
        warningList = []
        violationList = []
    }
    
    init(json: JsonElement) {
        hasAnswer = !json.ordictValue.isEmpty
        isOK = json["ok"].bool ?? false
        errorList = json["error_list"].arrayValue.map(parseResponseError)
        warningList = json["warning_list"].arrayValue.map(parseResponseWarning)
        violationList = parseResponseViolation(json: json["violation_list"])
    }
    
    var isMissingConnection: Bool {
        return !hasAnswer
    }
    
    var hasSpecificError: Bool {
        guard errorList.isEmpty else { return true }
        guard warningList.isEmpty else { return true }
        guard violationList.isEmpty else { return true }
        return false
    }
}

struct HTTPFileConfig {
    let uploadID: String
    let name: String
    let mime: String
    let mediaType: String?
    let access: String
    let downloadable: Bool
    let duration: Int?
    let pixelSize: CGSize?
    let contents: Data
    let params: [JsonElement]
}

struct HTTPFileUploadConfig {
    let url: URL
    let key: String
    let date: String
    let policy: String
    let credential: String
    let algorithm: String
    let signature: String
}

struct HTTPMediaUploadConfig {
    let url: URL
    let ts: Int
    let sign: String
    let metadata: String
}

enum HTTPUploadAck {
    case success(key: String, link: String)
    case cannotPrepare
    case possibleMalware
    case error(Error?)
}

enum BodyEncoding {
    case url
    case json
}

enum RestConnectionBehavior {
    case regular
    case ephemeral(priority: Float)
}

enum RestConnectionTarget {
    case url(String)
    case build(endpoint: String?, scope: RestConnectionTargetBuildScope, path: String)
}

struct RestConnectionTargetBuildScope: Equatable {
    enum Kind {
        case specific
        case chatServer
    }
    
    let kind: Kind
    let value: String
    
    static let api = RestConnectionTargetBuildScope(kind: .specific, value: "api")
    static let telephony = RestConnectionTargetBuildScope(kind: .specific, value: "telephony")
    static let telemetry = RestConnectionTargetBuildScope(kind: .specific, value: "telemetry")
    static let chatServer = RestConnectionTargetBuildScope(kind: .chatServer, value: String())
}

struct RestConnectionResult {
    let url: URL
    let status: RestResponseStatus
    let headers: [String: String]
    let body: JsonElement
    
    init(
        url: URL,
        status: RestResponseStatus,
        headers: [String: String],
        body: JsonElement
    ) {
        self.url = url
        self.status = status
        self.headers = headers
        self.body = body
    }
}

struct RestRequestOptions {
    enum Body {
        case omit
        case simple(BodyPayload)
        case json(BodyPayload)
    }
    
    enum BodyPayload {
        case object(JsonElement)
        case params([JsonElement])
    }
    
    let behavior: RestConnectionBehavior
    let method: RestRequestMethod
    let headers: [String: String]
    let query: [JsonElement]
    let body: Body
    
    init(
        behavior: RestConnectionBehavior,
        method: RestRequestMethod,
        headers: [String: String],
        query: [JsonElement],
        body: Body
    ) {
        self.behavior = behavior
        self.method = method
        self.headers = headers
        self.query = query
        self.body = body
    }
}

fileprivate func parseResponseError(json: JsonElement) -> HTTPResponseStatus.Failure {
    switch json.stringValue {
    case "user_not_found_or_invalid_password": return .passwordInvalid
    case "invalid_token": return .tokenInvalid
    case "access_denied": return .accessDenied
    case "email_not_found": return .emailNotFound
    case "account_is_blocked": return .accountBlocked
    case "invalid_restore_code": return .codeInvalid
    case "from_phone_equals_to_phone": return .calleeEqualsCaller
    case "call_already_exist": return .callExists
    case "service_unavailable_for_country": return .unavailableForCountry
    case "old_and_new_password_equals": return .newEqualsOld
    case "technical_error": return .technicalError
    case "temporarily_unavailable": return .temporaryUnavailable
    case "mfa_required": return .mfaRequired
    case "bad_request": return .badRequest
    default: return .unknown
    }
}

fileprivate func parseResponseWarning(json: JsonElement) -> HTTPResponseStatus.Warning {
    switch json.stringValue {
    default: return .unknown
    }
}

fileprivate func parseResponseViolation(json: JsonElement) -> [HTTPResponseStatus.Violation] {
    guard let strings = json.stringToStringMap else { return [] }
    return strings.map { return "\($0).\($1)" }
}
