import Foundation
import UIKit
import JivoSDK

final class AppDelegate: UIResponder, UIApplicationDelegate {
    private func handleUserInfo(secureUserToken: String) {
        JivoSDK.session.startUp(channelID: "abcdef", userToken: secureUserToken)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        JivoSDK.notifications.setPushToken(data: deviceToken)
    }
}

final class ProfileViewController {
}
