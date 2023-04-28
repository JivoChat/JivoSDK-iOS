//
//  SdkEngineDrivers.swift
//  JivoSDK
//
import Foundation
import JivoFoundation
import KeychainSwift
import JMTimelineKit

extension CacheDriverItem {
    static let activeLogs = CacheDriverItem(fileName: "jivosdk.active.logs")
    static let archiveLogs = CacheDriverItem(fileName: "jivosdk.archive.logs")
}

struct SdkEngineDrivers {
    let journalDriver: IJournalDriver
    let keychainDriver: IKeychainDriver
    let preferencesDriver: IPreferencesDriver
    let databaseDriver: JVIDatabaseDriver
    let cacheDriver: ICacheDriver
    let schedulingDriver: ISchedulingDriver
    let reachabilityDriver: IReachabilityDriver
    let photoLibraryDriver: IPhotoLibraryDriver
    let cameraDriver: ICameraDriver
    let restConnectionDriver: IRestConnectionDriver
    let liveConnectionDriver: ILiveConnectionDriver
    let webSocketDriver: ILiveConnectionDriver
    let apnsDriver: IApnsDriver
}

struct SdkEngineDriversFactory {
    let workingThread: JVIDispatchThread
    let namespace: String
    let userDefaults: UserDefaults
    let keychain: KeychainSwift
    let timelineCache: JMTimelineCache
    let fileManager: FileManager
    let urlSession: URLSession
    let schedulingCore: ISchedulingCore
    let jsonPrivacyTool: JVJsonPrivacyTool
    let outgoingPackagesAccumulator: AccumulatorTool<Data>

    func build() -> SdkEngineDrivers {
        let cacheDriver = buildCacheDriver(namespace: namespace)
        let preferencesDriver = buildPreferencesDriver()
        
        return SdkEngineDrivers(
            journalDriver: buildJournalDriver(cacheDriver: cacheDriver),
            keychainDriver: buildKeychainDriver(keychain: keychain, namespace: namespace),
            preferencesDriver: preferencesDriver,
            databaseDriver: buildCoreDataDriver(fileURL: cacheDriver.url(item: .live)?.jv_excludedFromBackup()),
            cacheDriver: cacheDriver,
            schedulingDriver: buildSchedulingDriver(schedulingCore: schedulingCore),
            reachabilityDriver: buildReachabilityDriver(),
            photoLibraryDriver: buildPhotoLibraryDriver(),
            cameraDriver: buildCameraDriver(),
            restConnectionDriver: buildRestConnectionDriver(preferencesDriver: preferencesDriver),
            liveConnectionDriver: buildLiveConnectionDriver(flushingInterval: 0, voip: false),
            webSocketDriver: buildWebSocketDriver(pingTimeInterval: 20, pongTimeInterval: 30, pingCharacter: " ", pongCharacter: " ", signToRemove: "\n"),
            apnsDriver: buildApnsDriver()
        )
    }
    
    private func buildJournalDriver(cacheDriver: ICacheDriver) -> IJournalDriver {
        let activeURL = cacheDriver.url(item: .activeLogs) ?? URL(fileURLWithPath: "/tmp/active.log")
        let archiveURL = cacheDriver.url(item: .archiveLogs) ?? URL(fileURLWithPath: "/tmp/archive.log")
        return JournalDriver(activeURL: activeURL, archiveURL: archiveURL, destination: .all)
    }
    
    private func buildKeychainDriver(keychain: KeychainSwift, namespace: String) -> IKeychainDriver {
        let driver = KeychainDriver(storage: keychain, namespace: namespace)
//        driver.migrate()
        return driver
    }
    
    private func buildPreferencesDriver() -> IPreferencesDriver {
        let driver = PreferencesDriver(storage: userDefaults, namespace: namespace)
//        driver.migrate()
        driver.registerDefaultValues()
        return driver
    }
    
    private func buildCoreDataDriver(fileURL: URL?) -> JVIDatabaseDriver {
        final class Environment: JVIDatabaseEnvironment {
            private let timelineCache: JMTimelineCache
            
            init(timelineCache: JMTimelineCache) {
                self.timelineCache = timelineCache
            }
            
            func performMessageRecalculate(uid: String) {
                timelineCache.resetSize(for: uid)
            }
        }
        
        return JVDatabaseDriver(
            thread: workingThread,
            fileManager: .default,
            namespace: namespace,
            writing: .anyThread,
            fileURL: fileURL,
            environment: Environment(
                timelineCache: timelineCache
            ),
            localizer: loc
        )
    }
    
    private func buildCacheDriver(namespace: String) -> ICacheDriver {
        return CacheDriver(storage: fileManager, namespace: namespace)
    }
    
    private func buildSchedulingDriver(schedulingCore: ISchedulingCore) -> ISchedulingDriver {
        return SchedulingDriver(core: schedulingCore)
    }
    
    private func buildReachabilityDriver() -> IReachabilityDriver {
        return ReachabilityDriver()
    }
    
    private func buildPhotoLibraryDriver() -> IPhotoLibraryDriver {
        return PhotoLibraryDriver()
    }
    
    private func buildCameraDriver() -> ICameraDriver {
        return CameraDriver()
    }
    
    private func buildRestConnectionDriver(preferencesDriver: IPreferencesDriver) -> IRestConnectionDriver {
        return SDKRestConnectionDriver()
    }
    
    private func buildLiveConnectionDriver(flushingInterval: TimeInterval, voip: Bool, endingSign: String? = nil) -> ILiveConnectionDriver {
        return LiveConnectionDriver(
            flushingInterval: flushingInterval,
            voip: voip,
            endingSign: endingSign,
            jsonPrivacyTool: jsonPrivacyTool
        )
    }
    
    private func buildWebSocketDriver(pingTimeInterval: TimeInterval, pongTimeInterval: TimeInterval, pingCharacter: Character, pongCharacter: Character, signToRemove: String? = nil) -> ILiveConnectionDriver {
        return WebSocketDriver(
            outgoingPackagesAccumulator: outgoingPackagesAccumulator,
            pingTimeInterval: pingTimeInterval,
            pongTimeInterval: pongTimeInterval,
            pingCharacter: pingCharacter,
            pongCharacter: pongCharacter,
            signToRemove: signToRemove,
            jsonPrivacyTool: jsonPrivacyTool
        )
    }
    
    private func buildApnsDriver() -> IApnsDriver {
        return ApnsDriver()
    }
}
