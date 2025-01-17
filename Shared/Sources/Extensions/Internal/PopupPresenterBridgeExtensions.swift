//
// Created by Stan Potemkin on 2018-12-03.
// Copyright (c) 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit

extension IPopupPresenterBridge {
    func jv_warnAndDismiss(title: String?, message: String?, dismissKind: PopupPresenterItem.DismissKind) {
        displayAlert(
            within: .auto,
            title: title,
            message: message,
            items: [
                .dismiss(dismissKind)
            ])
    }
    
    func jv_warnNetworkMissing() {
        displayAlert(
            within: .auto,
            title: loc["status_missing_connection"],
            message: loc["suggest_check_internet_access"],
            items: [
                .dismiss(.understand)
            ])
    }
    
    func warnFeatureDisabled(caption: String? = nil) {
        displayAlert(
            within: .auto,
            title: caption ?? loc["Me.DisabledFeature.Common"],
            message: nil,
            items: [
                .dismiss(.understand)
            ])
    }
    
    func informFeatureAvailableSincePro() {
        displayAlert(
            within: .auto,
            title: loc["Dialog.FeatureForPro.Description"],
            message: nil,
            items: [
                .dismiss(.close)
            ])
    }
    
    #if ENV_APP
    func warnFeatureNeedsPro(telemeteryService: ITelemetryService?) {
        displayAlert(
            within: .auto,
            title: loc["Dialog.FeatureForPro.Description"],
            message: nil,
            items: [
                .action(loc["Dialog.FeatureForPro.ToSupport"], .icon(.quit), .regular { _ in
                    NotificationCenter.default.post(name: .OpenSupport, object: nil)
                }),
                .dismiss(.cancel)
            ])
    }
    #endif
    
    func warnFeatureForOperators() {
        displayAlert(
            within: .auto,
            title: loc["Me.DisabledFeature.isNotOperator"],
            message: nil,
            items: [
                .dismiss(.close)
            ])
    }
    
    func warnFeatureForAdmins() {
        displayAlert(
            within: .auto,
            title: loc["Me.DisabledFeature.isNotAdmin"],
            message: nil,
            items: [
                .dismiss(.close)
            ])
    }
    
    func warnOperatingRevoked() {
        displayAlert(
            within: .auto,
            title: String(),
            message: loc["Me.OperatorStatusRevoked"],
            items: [
                .dismiss(.close)
            ])
    }
    
    func warnMissingMediaAccess() {
        displayAlert(
            within: .auto,
            title: loc["JV_SystemAccess_Gallery_NoPermission", "Media.Access.Missing"],
            message: loc["JV_SystemAccess_Gallery_RequestReason", "Media.Access.Suggestion"],
            items: [
                .action(loc["JV_Common_Captions_Settings", "Common.Open"], .noicon, .regular { _ in
                    guard let url = URL.jv_privacy() else { return }
                    UIApplication.shared.open(url)
                }),
                .dismiss(.cancel)
            ])
    }
    
    func warnSomeoneOnCallAlready() {
        displayAlert(
            within: .auto,
            title: loc["Chat.AcceptanceFailure.OnCall"],
            message: nil,
            items: [
                .dismiss(.close)
            ])
    }
    
    func informTimeBreak() {
        informShortly(
            message: loc["Alert.TimeBreak.Title"],
            icon: UIImage(named: "coffee_break"),
            options: [.template])
    }
    
    func informStatusChange() {
        informShortly(
            message: loc["Alert.StatusUpdate.Title"],
            icon: UIImage(named: "checkmark.circle"),
            options: [.template, .scale])
    }
    
    func informCopied() {
        informShortly(
            message: loc["Common.Copied"],
            icon: nil,
            options: [.template])
    }
    
    func informNone() {
        informShortly(
            message: nil,
            icon: nil,
            options: [.template])
    }
    
    func informToRestart() {
        displayAlert(
            within: .auto,
            title: "Please restart the app",
            message: nil,
            items: [
            ])
    }
    
    func informThankYou() {
        informShortly(
            message: loc["Common.ThankYou"],
            icon: nil,
            options: [.template])
    }
    
    func informPreview(image: UIImage) {
        informShortly(
            message: nil,
            icon: image,
            options: [.scale])
    }
    
    func informFeedbackSent() {
        informShortly(
            message: loc["Feedback.ThankYou"],
            icon: nil,
            options: [.template])
    }
    
    func informAboutChatHasBeenKept() {
        informShortly(
            message: loc["Informer.Chat.HasBeenKept"],
            icon: nil,
            options: [.template])
    }
    
    func informAboutChatHasBeenArchived() {
        informShortly(
            message: loc["Informer.Chat.HasBeenArchived"],
            icon: nil,
            options: [.template])
    }
    
    func informTransferCancelled() {
        informShortly(
            message: loc["Alert.TransferCancelled.Title"],
            icon: nil,
            options: [.template])
    }
    
    func informInvitationCancelled() {
        informShortly(
            message: loc["Alert.InvitationCancelled.Title"],
            icon: nil,
            options: [.template])
    }
    
    func informCallHangup() {
        informShortly(
            message: loc["Alert.CallHangup.Title"],
            icon: nil,
            options: [.template])
    }
    
    func informWorktimeSnooze() {
        informShortly(
            message: loc["Informative.Snoozed"],
            icon: nil,
            options: [.template])
    }
    
    func informTestApnsSuccess() {
        informShortly(
            message: loc["Alert.TestApnsSuccess.Title"],
            icon: nil,
            options: [.template])
    }
    
    func warnAboutOffline() {
        informShortly(
            message: loc["Me.Connection.Offline"],
            icon: nil,
            options: [.template])
    }
    
    func warnAboutNoExtIdRegistration() {
        informShortly(
            message: loc["Me.Connection.NoExtIdRegistration"],
            icon: nil,
            options: [.template])
    }
    
    func alertAboutWorktimeDays() {
        displayMenu(
            within: .auto,
            anchor: nil,
            title: loc["Alert.AtLeastOneWorkday.Title"],
            message: nil,
            items: [
                .dismiss(.cancel)
            ])
    }
    
    func notifyAboutMediaExtractionFailed() {
        informShortly(
            message: loc["Media.Uploading.ExtractionError"],
            icon: nil,
            options: [.template])
    }
    
    func notifyAboutMediaTooLarge(limit: Int) {
        informShortly(
            message: loc[format: "Media.Uploading.TooLarge", limit],
            icon: nil,
            options: [.template])
    }
    
    func notifyAboutMediaUploadingError() {
        journal {"Failed uploading"}
            .nextLine {"Failed to upload the file"}
        
        informShortly(
            message: loc["Media.Uploading.UploadingError"],
            icon: nil,
            options: [.template])
    }
    
    func pickGroupNotifications(group: ChatEntity, callback: @escaping (JVChatAttendeeNotifying) -> Void) {
        let map: [JVChatAttendeeNotifying: (title: String, preset: PopupPresenterItem.ActionIconPreset)] = [
            .everything: (title: loc["Teambox.Options.Everything"], preset: .checkmark),
            .nothing: (title: loc["Teambox.Options.Nothing"], preset: .checkmark),
            .mentions: (title: loc["Teambox.Options.Mentions"], preset: .checkmark),
        ]
        
        let actions: [PopupPresenterItem] = JVChatAttendeeNotifying.allCases.compactMap { option in
            guard let (title, preset) = map[option]
            else {
                return nil
            }
            
            if option == group.notifying {
                return .action(title, .icon(preset), .inactive)
            }
            else {
                return .action(title, .icon(preset), .regular { _ in
                    callback(option)
                })
            }
        }
        
        displayMenu(
            within: .auto,
            anchor: nil,
            title: nil,
            message: nil,
            items: actions + [
                .dismiss(.cancel)
            ])
    }
    
    func confirmKickingMemberFromChat(confirmationBlock: @escaping () -> Void) {
        displayAlert(
            within: .auto,
            title: loc["Details.KickFromChat.Title"],
            message: nil,
            items: [
                .action(loc["Details.KickFromChat.Confirm"], .icon(.confirm), .regular { _ in
                    confirmationBlock()
                }),
                .dismiss(.cancel)
            ])
    }
    
    func closableAlert(title: String?, message: String?) {
        displayAlert(
            within: .auto,
            title: title,
            message: message,
            items: [
                .dismiss(.close)
            ])
    }
}
