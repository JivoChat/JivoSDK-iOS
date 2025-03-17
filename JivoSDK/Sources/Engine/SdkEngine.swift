//
//  SdkEngine.swift
//  JivoSDK
//

import Foundation
import UIKit
import KeychainSwift
import JMTimelineKit
import JMCodingKit

struct SdkConfig {
    static let replyLengthLimit = 1000
    static let attachmentsNumberLimit = 2
    
    struct uploadingLimit {
        static let megabytes = 10
        static var bytes: UInt64 { return UInt64(megabytes * 1024 * 1024) }
    }
}

protocol ISdkEngine: AnyObject {
    var sessionContext: ISdkSessionContext { get }
    var clientContext: ISdkClientContext { get }
    var messagingContext: ISdkMessagingContext { get }
    var timelineCache: JMTimelineCache { get }
    var networking: INetworking { get }
    var drivers: SdkEngineDrivers { get }
    var repositories: SdkEngineRepositories { get }
    var providers: SdkEngineProviders { get }
    var services: SdkEngineServices { get }
    var bridges: SdkEngineBridges { get }
    var managers: SdkEngineManagers { get }
    var scenarioRunner: ISdkEngineScenarioRunner { get }
    var threads: SdkEngineThreads { get }
    func retrieveCacheBundle(token: String?) -> SdkEngineUserCacheBundle
}

final class SdkEngineUserCacheBundle {
    let contactFormCache = ChatTimelineContactFormCache()
}

final class SdkEngine: ISdkEngine {
    static let shared = SdkEngineFactory.build()

    let sessionContext: ISdkSessionContext
    let clientContext: ISdkClientContext
    let messagingContext: ISdkMessagingContext
    
    let timelineCache: JMTimelineCache
    
    let drivers: SdkEngineDrivers
    let repositories: SdkEngineRepositories
    let providers: SdkEngineProviders
    let networkingHelper: INetworkingHelper
    let services: SdkEngineServices
    let bridges: SdkEngineBridges
    let networking: INetworking
    let managers: SdkEngineManagers
    let scenarioRunner: ISdkEngineScenarioRunner
    let threads: SdkEngineThreads

    internal let networkEventDispatcher: INetworkingEventDispatcher

    private let namespace: String
    private let userDefaults: UserDefaults
    private let keychain: KeychainSwift
    private let fileManager: FileManager
    private let schedulingCore: ISchedulingCore
    private var tokenToCacheBundleMapping = [String: SdkEngineUserCacheBundle]()

    init(
        namespace: String,
        userDefaults: UserDefaults,
        keychain: KeychainSwift,
        fileManager: FileManager,
        urlSession: URLSession,
        schedulingCore: ISchedulingCore
    ) {
        setJournalLevel(.full)
        
        loc.searchingRulesProvider = { lang in
            return [
                JVLocalizerSearchingRule(
                    location: Bundle.main.path(forResource: lang, ofType: "lproj"),
                    namespace: "jivosdk:"
                ),
                JVLocalizerSearchingRule(
                    location: Bundle(for: Jivo.self).path(forResource: lang, ofType: "lproj"),
                    namespace: .jv_empty
                ),
                JVLocalizerSearchingRule(
                    location: Bundle.main.path(forResource: lang, ofType: "lproj", inDirectory: "Jivo_JivoSDK.bundle"),
                    namespace: .jv_empty
                ),
                JVLocalizerSearchingRule(
                    location: Bundle.main.path(forResource: "Base", ofType: "lproj"),
                    namespace: "jivosdk:"
                ),
                JVLocalizerSearchingRule(
                    location: Bundle(for: Jivo.self).path(forResource: "Base", ofType: "lproj"),
                    namespace: .jv_empty
                ),
                JVLocalizerSearchingRule(
                    location: Bundle.main.path(forResource: "Base", ofType: "lproj", inDirectory: "Jivo_JivoSDK.bundle"),
                    namespace: .jv_empty
                ),
            ]
        }
        
        AgentEntity.registerDefaultDisplayName(value: loc["JV_DisplayName_Agent_Default", "agent_name_default"])

        JVDesign.attachTo(
            application: .shared,
            window: UIWindow(frame: UIScreen.main.bounds))
        
        threads = SdkEngineThreadsFactory(
        ).build()
        
        let parsingQueue = DispatchQueue(label: "jivosdk.networking.mapper.queue", qos: .userInteractive)
        let uploadingQueue = DispatchQueue(label: "jivosdk.engine.fileuploader.queue", qos: .userInteractive)

        self.namespace = namespace
        self.userDefaults = userDefaults
        self.keychain = keychain
        self.fileManager = fileManager
        self.schedulingCore = schedulingCore
        
        self.timelineCache = JMTimelineCache()
        
        let jsonPrivacyTool = JVJsonPrivacyTool(
            enabled: true,
            rules: [
                JsonPrivacyRule(
                    condition: nil,
                    masks: [
                        JsonPrivacyRule.Mask(path: "password", replacement: .stars),
                        JsonPrivacyRule.Mask(path: "access_token", replacement: .trimming)
                    ]
                ),
            ]
        )

        let outgoingPackagesAccumulator = AccumulatorTool<(JsonElement?, Data)>()
        
        let drivers = SdkEngineDriversFactory(
            workingThread: threads.workerThread,
            namespace: namespace,
            userDefaults: userDefaults,
            keychain: keychain,
            timelineCache: timelineCache,
            fileManager: fileManager,
            urlSession: urlSession,
            schedulingCore: schedulingCore,
            jsonPrivacyTool: jsonPrivacyTool,
            outgoingPackagesAccumulator: outgoingPackagesAccumulator
        ).build()
        self.drivers = drivers
        
        let repositories = SdkEngineRepositoriesFactory(
            databaseDriver: drivers.databaseDriver
        ).build()
        self.repositories = repositories
        
        let bridges = SdkEngineBridgesFactory(
            photoLibraryDriver: drivers.photoLibraryDriver,
            cameraDriver: drivers.cameraDriver
        ).build()
        self.bridges = bridges
        
        providers = SdkEngineProvidersFactory(
            drivers: drivers
        ).build()
        
        networkingHelper = NetworkingHelper(
            uuidProvider: providers.uuidProvider,
            keychainTokenProvider: {drivers.keychainDriver.userScope().retrieveAccessor(forToken: .token).string},
            jsonPrivacyTool: jsonPrivacyTool
        )
        
        let sessionContext = SdkSessionContext(
            accountConfigAccessor: drivers.preferencesDriver.retrieveAccessor(forToken: .accountConfig),
            endpointConfigAccessor: drivers.preferencesDriver.retrieveAccessor(forToken: .endpointConfig),
            rateConfigAccessor: drivers.preferencesDriver.retrieveAccessor(forToken: .rateConfig)
        )
        self.sessionContext = sessionContext
        
        let clientContext = SdkClientContext(
            databaseDriver: drivers.databaseDriver
        )
        self.clientContext = clientContext
        
        let messagingContext = SdkMessagingContext()
        self.messagingContext = messagingContext
        
        let networkServiceFactory = SdkEngineNetworkingFactory(
            workerThread: threads.workerThread,
            networkingHelper: networkingHelper,
            socketDriver: drivers.webSocketDriver,
            restConnectionDriver: drivers.restConnectionDriver,
            localeProvider: providers.localeProvider,
            uuidProvider: providers.uuidProvider,
            preferencesDriver: drivers.preferencesDriver,
            keychainDriver: drivers.keychainDriver,
            jsonPrivacyTool: jsonPrivacyTool,
            urlBuilder: { standardURL, endpoint, scope, path -> URL? in
                switch scope {
                case .replace(RestConnectionTargetBuildScope.api.value):
                    guard let config = sessionContext.endpointConfig,
                          var components = URLComponents(string: config.apiHost)
                    else {
                        return nil
                    }

                    if let path = path {
                        components.path = path.hasPrefix("/") ? (path) : ("/" + path)
                    }
                    
                    return components.url
                    
                default:
                    guard var components = URLComponents(url: standardURL, resolvingAgainstBaseURL: false),
                          let standardHost = components.host
                    else {
                        return nil
                    }

                    guard standardHost.split(separator: ".").first == "api"
                    else {
                        return nil
                    }
                    
                    if let endpoint = endpoint {
                        let endpointOuter = endpoint.split(separator: ":")
                        let endpointInner = endpointOuter.first?.split(separator: ".") ?? .jv_empty

                        switch scope {
                        case .original:
                            components.host = endpointInner.joined(separator: ".")
                            components.port = sessionContext.endpointConfig?.chatserverPort.jv_valuable
                        case .replace(let value):
                            let tail = endpointInner.dropFirst(1).map(String.init)
                            components.host = ([value] + tail).joined(separator: ".")
                        }
                    }
                    
                    if let path = path {
                        components.path = path.hasPrefix("/") ? (path) : ("/" + path)
                    }

                    return components.url
                }
            }
        )
        
        self.networking = networkServiceFactory.build()
        
        networkEventDispatcher = SdkNetworkingEventDispatcherFactory(
            outputThread: threads.workerThread,
            parsingQueue: parsingQueue,
            slicer: NetworkingSlicer(
                defaultTimeInterval: 0.4,
                prolongedTimeInterval: 0.5,
                timersTolerance: 0.1
            )
        ).build()
        networkEventDispatcher.attach(to: networking.eventObservable)
        
        services = SdkEngineServicesFactory(
            sessionContext: sessionContext,
            clientContext: clientContext,
            workerThread: threads.workerThread,
            networking: networking,
            networkingHelper: networkingHelper,
            networkingEventDispatcher: networkEventDispatcher,
            drivers: drivers,
            providers: providers
        ).build()
        
        managers = SdkEngineManagersFactory(
            apnsEnvironment: UIApplication.shared.jv_detectApnsEnvironment(),
            workerThread: threads.workerThread,
            uploadingQueue: uploadingQueue,
            sessionContext: sessionContext,
            clientContext: clientContext,
            messagingContext: messagingContext,
            networkEventDispatcher: networkEventDispatcher,
            uuidProvider: providers.uuidProvider,
            networking: networking,
            networkingHelper: networkingHelper,
            systemMessagingService: services.systemMessagingService,
            typingCacheService: services.typingCacheService,
            remoteStorageService: services.remoteStorageService,
            apnsService: services.apnsService,
            localeProvider: providers.localeProvider,
            pushCredentialsRepository: repositories.pushCredentialsRepository,
            preferencesDriver: drivers.preferencesDriver,
            keychainDriver: drivers.keychainDriver,
            reachabilityDriver: drivers.reachabilityDriver,
            databaseDriver: drivers.databaseDriver,
            schedulingDriver: drivers.schedulingDriver,
            cacheDriver: drivers.cacheDriver
        ).build()
        
        scenarioRunner = SdkEngineScenarioRunner(
            thread: threads.workerThread,
            managers: managers
        )
    }
    
    func retrieveCacheBundle(token: String?) -> SdkEngineUserCacheBundle {
        guard let token = token
        else {
            return SdkEngineUserCacheBundle()
        }
        
        if let bundle = tokenToCacheBundleMapping[token] {
            return bundle
        }
        else {
            let bundle = SdkEngineUserCacheBundle()
            tokenToCacheBundleMapping[token] = bundle
            return bundle
        }
    }
}

extension SdkEngine: BaseViewControllerSatellite {
    var keyboardListenerBridge: IKeyboardListenerBridge {
        return bridges.keyboardListenerBridge
    }
    
    func viewWillAppear(viewController: UIViewController) {
    }
}
