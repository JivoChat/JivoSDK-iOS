# Project setup

Permissions and Push Notifications

## #1: Application Permissions

SDK needs access to device camera and gallery.

For necessary permissions, add these appropriate keys to your `Info.plist`:

| key                            | Purpose
| ---                            | ---
| NSCameraUsageDescription       | Access to camera so that your customers can take photos with camera
| NSPhotoLibraryUsageDescription | Access to gallery so that your customers can send photos from gallery

> Warning: Without these keys, your app may crash when SDK will be accessing camera or gallery

## #2: Apple Push Notifications service

#### Capabilities

Make sure you have `Push Notifications` capability in your project settings under `Signing & Capabilities` tab.

> Important: Push Notifications are sent __only in production environment__
>
> In other words, they can only be tested when distributed via AdHoc, TestFlight, or App Store.

#### Localization

Our Push Notifications use client-side localization (read more in ["Localize Your Alert Messages"](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification) by Apple), for which localization keys are specified as title and message, so you need to add following keys into localization files `Localizable.strings` of your project:

| Key                | Purpose
| ---                | ---
| `JV_MESSAGE_TITLE` | Push Notification header key
| `JV_MESSAGE`       | Push Notification body key

In addition to these keys, we also pass extra arguments within Push Notification payload which you can also use when localizing text:
- First argument contains a person name
- Second argument contains a message text

Here is an example of how the localization might look:

```
"JV_MESSAGE_TITLE" = "Support Team"; 
"JV_MESSAGE" = "%1$@: %2$@";
```
