# Configure a project

<!--See also – <doc:setup_project_reactnative>-->

## Overview

Please

## #1: Application Permissions

JivoSDK uses the device's camera. It also needs access to the photo gallery.

To obtain the necessary permissions, add the appropriate keys to your `Info.plist`:

| key                            | Purpose
| ---                            | ---
| NSCameraUsageDescription       | The key and description for the key are needed to access the device's camera so that your customers can send photos from the camera to the support chat
| NSPhotoLibraryUsageDescription | The key and description for the key are needed to access the device's photo gallery so that your customers can send photos from the gallery to the support chat

> Warning: Without these keys, your app may crash when JivoSDK will be accessing camera or gallery

## #2: Configure APNs

PUSH notifications are only sent when the connection between **JivoSDK** and our server is closed

The connection become broken when the chat window closes. After that, we start sending PUSH notifications

Thus, you can customize the display of notifications from **Jivo** within your application for the foreground state

> Important: Push notifications work _only in production environments_,
>
> in other words, they can only be tested when distributed via AdHoc, TestFlight, or the App Store.

> Tip: It's possible to test your application logic in the simulator if you save the content of the PUSH notification to a separate file, for example, with the name `jivo_sdk_push.json`, and then use the command:

```sh
xcrun simctl push booted {your_app_bundle_id} {path/to/jivo_sdk_push.json}
```

## #3: Signing & Capabilities

Add the (capability) `Push Notifications` item in the project settings, in the `Signing & Capabilities` tab, if you have not added it yet.

## #4: Translations in Localizable.strings

Our push notifications use client-side localization (read more in ["Localize Your Alert Messages" by Apple](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification), for which localization keys are specified as the title and message, so you need to add lines for the following keys to the localization files `Localizable.strings` of your project:

| Key                | Purpose
| ---                | ---
| `JV_MESSAGE_TITLE` | PUSH header key
| `JV_MESSAGE`       | PUSH message key

In addition to the keys, in the body of the PUSH notification we also pass arguments that you can also use when localizing the text:
- The first argument contains the name of the interlocutor who sent the message
- The second argument contains the text of the message

Here is an example of how the localization of the text of a PUSH notification might look like in the `*.strings` localization file for any language:

```
"JV_MESSAGE_TITLE" = "Support Team"; 
"JV_MESSAGE" = "%1$@: %2$@";
```

## #5: APNs Key

Add a key for Apple Push Notifications service (APNs) in the `Keys` section of your account page in [developer.apple.com](developer.apple.com) (or use an already existing APNs key),
save it - the service will prompt you to download the key as a file with the `p8` extension.

> Important: After creating the key for APNs, keep it in a safe place.
> The generated APNs key can be downloaded _only once_!

Add the APNs key as a `p8` file to your `Mobile SDK` channel.

To do this, go to `"Management" -> "Channels" -> "Mobile SDK" (button "Settings") -> "PUSH Settings" -> "Upload P8 key"`.

![Channel APNs Settings: upload the key](channel_setup_3)

Also, in addition to the APNs key itself, you will need to specify:

| Parameter | Purpose
| ---       | ---
| key_id    | ID of the key
| team_id   | The Team ID of your Apple Developer Program account
| bundle_id | Bundle ID of your app

![Channel APNs Settings: specify the parameters](channel_setup_4)
