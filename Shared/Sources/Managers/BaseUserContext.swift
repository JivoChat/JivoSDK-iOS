//
//  IBaseUserContext.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 12.09.2020.
//  Copyright © 2020 JivoSite. All rights reserved.
//

import Foundation

protocol IBaseUserContext: AnyObject {
    var remoteStorageToken: String? { get }
    func havingAccess(callback: @escaping () -> Void)
    func isPerson(ofKind kind: String, withID ID: Int) -> Bool
}

//protocol IUserContext: IBaseUserContext {
//    var user: Agent? { get }
//    var identity: UserIdentity? { get }
//    var meta: UserMeta { get }
//    var telephony: APITelephony? { get set }
//    var connectionStatusObservable: JVBroadcastTool<AuthConnectivity> { get }
//    var connectionStatus: AuthConnectivity { get }
//    var activityObservable: JVBroadcastUniqueTool<UserActivity> { get }
//    var activity: UserActivity { get }
//    var isAccessible: Bool { get }
//    var techConfig: UserTechConfig { get }
//    var serviceZoneLink: String? { get }
//    func prepareForSDK(userID: Int, siteID: Int)
//    func retrieveAccess(needRequest: Bool, callback: @escaping (AuthTokenMeta, UserIdentity?) -> Void)
//    func updateConnected(sinceDate: Date?, reviewService: IReviewService)
//    func canReadSession() -> Bool
//    func readSession() -> JVAgentGeneralChange?
//    func saveSession(change: JVAgentGeneralChange, telemetryService: ITelemetryService)
//    func storeUserID(_ userID: Int, readMeta: Bool)
//    func disableSession()
//    func discardSession()
//    func updateConfig(_ config: UserTechConfig)
//    func updateInfo(hasLicense: Bool)
//    func featureState(_ feature: UserFeature) -> UserFeatureState
//    func featureState(_ feature: UserFeature, fallback: UserFeatureState) -> UserFeatureState
//    func requestAction(_ action: WorkspaceRequestedAction, timeout: TimeInterval, block: @escaping () -> Void)
//    func respondAction(_ action: WorkspaceRequestedAction, success: Bool)
//}
