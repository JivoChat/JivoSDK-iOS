//
//  JivoImpl.swift
//  SDK
//
//  Created by Stan Potemkin on 21.03.2023.
//

import Foundation

/**
 > Important: Full documentation is here:  
 > <https://jivochat.github.io/JivoSDK-iOS/>

 * ## Quick start
 
    First, start SDK session after you have authorized your client wherever in your logic (like example below):  
    [How to generate User Token in JWT format](https://jivochat.github.io/JivoSDK-iOS/documentation/jivosdk/common_user_token)
    ```swift
    func handleUserLogin() {
        let client = Jivo.session.setup(
            widgetID: "YOUR_WIDGET_ID",
            clientIdentity: .jwt("USER_TOKEN_IN_JWT_FORMAT")
        )
 
        client.setClientInfo(...) // optional
        client.setCustomData(...) // optional
 
        client.listenToUnreadCounter { number in
            // read updates here
        }
    }
    ```

    Second, present the SDK onto screen whenever you need it (like example below):
    ```swift
    // UIKit
    func handleSupportButtonTap() {
        if let navigationController {
            Jivo.display.push(into: navigationController)
        }
        else {
            Jivo.display.present(over: self)
        }
    }
 
    // SwiftUI
    var body: some View {
        Text("Tech Support")
            .fullScreenCover(isPresented: $shouldPresentChat) {
                Jivo.display.makeScreen(.modal)
            }
    }
    ```
 
    To support Push Notifications, you should provide us Push Token (like example below):
    ```swift
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // ... your existing logic ...
 
        Jivo.notifications.setPushToken(data: deviceToken)
    }
 
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // ... your existing logic ...
 
        Jivo.notifications.setPushToken(error: error)
    }
    ```

    To handle and display incoming notifications, please implement three another methods (like example below):
    ```swift
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // ... your existing logic ...
 
        UNUserNotificationCenter.current().delegate = self
 
        if Jivo.notifications.handleLaunch(options: launchOptions) {
            Jivo.display.present(over: rootViewController)
        }
        
        return true
    }
 
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let result = Jivo.notifications.didReceiveRemoteNotification(userInfo: userInfo) {
            completionHandler(result)
            return
        }
 
        // ... your existing logic ...
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if let options = Jivo.notifications.willPresent(notification: notification, preferableOptions: .banner) {
            completionHandler(options)
            return
        }
 
        // ... your existing logic ...
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if Jivo.notifications.didReceive(response: response) {
            Jivo.display.present(over: rootViewController)
            completionHandler()
        }
 
        // ... your existing logic ...
    }
    ```
 
 * ## May be interesting for you:
 
    - [Basic SDK usage](https://jivochat.github.io/JivoSDK-iOS/tutorials/jivosdk/native_usage_basics)
    - [User token and history](https://jivochat.github.io/JivoSDK-iOS/documentation/jivosdk/common_user_token)
    - [UI customization](https://jivochat.github.io/JivoSDK-iOS/documentation/jivosdk/jvdisplaycontroller)
    - [Notifications localization](https://jivochat.github.io/JivoSDK-iOS/documentation/jivosdk/common_project_config/#Localization)
 */
@objc(Jivo)
public final class Jivo: NSObject {
    static let shared = Jivo()
    let session = JVSessionController()
    let display = JVDisplayController()
    let notifications = JVNotificationsController()
    let debugging = JVDebuggingController()
}

func inform(messageProvider: () -> String) {
    print("Jivo: \(messageProvider())")
}
