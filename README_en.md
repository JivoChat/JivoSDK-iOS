# Jivo Mobile SDK for iOS

![Jivo Logo](./README_en/Resources/jivo_logo.svg)

1. [Introduction](#intro)
2. [Setting up a channel in Jivo](#channel)
3. [Preparing a mobile project](#prepare)
4. [Installing the Jivo Mobile SDK](#install)
5. [How to use the Jivo Mobile SDK](#usage)
6. [Detailed Jivo Mobile SDK API](#api)



# <a name="intro">Introduction</a>

**Jivo Mobile SDK** is a framework for integrating Jivo Business Chat into your application. Several API options are available for interacting with the SDK:

- Swift / Objective-C
- React Native



Current configuration:

- There is localization into languages: Russian, English, Spanish, Portuguese, Turkish
- File transfer works only with an active license
- No bitcode support
- May not work correctly when using a VPN



<img src="./README_en/Resources/sdk_chat_shot.jpeg" width=350 />



# <a name="channel">Setting up a channel in Jivo</a>

> For the **Jivo Mobile SDK** to work, you need a channel of type `"Mobile SDK"`.
> Its creation is only available in [Enterprise version of **Jivo**](https://www.jivochat.com/pricing/).

1. In your personal **Jivo** account, go to the screen `"Manage" -> "Channels"` and create a new channel there `"Mobile SDK"`.

!["Mobile SDK" Channel Creation](./README_en/Resources/channel_setup_1.jpeg)

2. Go to the settings of the created channel, section `"Options"`, and find the value `widget_id` in the `"Jivo Mobile SDK parametrs"` item. This value will be used everywhere in the **Jivo Mobile SDK** wherever a `channelID` is required.

> The `widget_id` field in the `"Mobile SDK"` channel settings
> and `channelID` field in the **Jivo Mobile SDK API** are the same.



!["Mobile SDK" Channel Settings](./README_en/Resources/channel_setup_2.jpeg)



# <a name="prepare">Preparing a mobile project</a>

In order for the **Jivo Mobile SDK** to fully work, there are several preparations to be made.

### Application Permissions

**Jivo Mobile SDK** uses the device's camera. He also needs access to the photo gallery. To obtain the necessary permissions, add the appropriate keys to your project's `Info.plist` file:

- `NSCameraUsageDescription`

    The key and description for the key are needed to access the device's camera so that your customers can send photos from the camera to the support chat

- `NSPhotoLibraryUsageDescription`

    The key and description for the key are needed to access the device's photo gallery so that your customers can send photos from the gallery to the support chat

### Setting up PUSH notifications

> Push notifications work <u>only in production environments</u>, in other words, they can only be tested when distributed via AdHoc, TestFlight, or the App Store.

> It's possible to test your application logic in the simulator if you save the content of the PUSH notification to a separate file, for example, with the name `jivo_sdk_push.json`, and then use the command:
> ````
> xcrun simctl push booted {your_app_bundle_id} {path/to/jivo_sdk_push.json}
> ````

> PUSH notifications are only sent when the connection between **Jivo Mobile SDK** and our server is closed. The connection become broken when the chat window closes. After that, we start sending PUSH notifications. Thus, you can customize the display of notifications from **Jivo** within your application for the foreground state.



##### Signing & Capabilities

Add the (capability) `Push Notifications` item in the project settings, in the `Signing & Capabilities` tab, if you have not added it yet.



##### Translations in Localizable.strings

Our push notifications use client-side localization (read more in ["Localize Your Alert Messages" by Apple](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification), for which localization keys are specified as the title and message, so you need to add lines for the following keys to the localization files `Localizable.strings` of your project:

- `"JV_MESSAGE_TITLE"`

    PUSH header key

- `"JV_MESSAGE"`

    PUSH message key



In addition to the keys, in the body of the PUSH notification we also pass arguments that you can also use when localizing the text:

- the first argument contains the name of the interlocutor who sent the message
- the second argument contains the text of the message



Here is an example of how the localization of the text of a PUSH notification might look like in the `*.strings` localization file for any language:

```
"JV_MESSAGE_TITLE" = "Support Team"; 
"JV_MESSAGE" = "%1$@: %2$@";
```



##### APNs Key

Add a key for Apple Push Notifications service (APNs) in the `Keys` section of your account page in [developer.apple.com](developer.apple.com) (or use an already existing APNs key),
save it - the service will prompt you to download the key as a file with the `p8` extension.

> After creating the key for APNs, keep it in a safe place.
> The generated APNs key can be downloaded <u>only once</u>!


Add the APNs key as a `p8` file to your `Mobile SDK` channel. To do this, go to `"Management" -> "Channels" -> "Mobile SDK" (button "Settings") -> "PUSH Settings" -> "Upload P8 key"`.

!["Mobile SDK" Channel PUSH Settings](./README_en/Resources/channel_setup_3.jpeg)

Also, in addition to the APNs key itself, you will need to specify:

- `key_id`

    ID of this key

- `team_id`

    The Team ID of your Apple Developer Program account

- `bundle_id`

    Bundle ID of your app

!["Mobile SDK" Channel PUSH Settings – Adding .p8 token](./README_en/Resources/channel_setup_4.jpeg)



# <a name="install">Installing the Jivo Mobile SDK</a>

### Requirements

To install the **Jivo Mobile SDK** in your Xcode project, you will need:
- Xcode 13.0 or newer
- CocoaPods 1.10.0 or newer
- Set `Deployment Target` in project to iOS 11.0 or newer

### Installation steps
1. Specify the following sources at the beginning of your project's `Podfile`:
```ruby
source 'https://github.com/CocoaPods/Specs.git' 
source 'https://github.com/JivoChat/JMSpecsRepo.git'
```

2. Add `JivoSDK` as a dependency in your `Podfile`:
```ruby
use_frameworks!

target :YourTargetName do
  pod 'JivoSDK' #, '~> 3.0'
end
```

> When connecting the SDK this way, `pod update` will install the latest version of the SDK available. If, for some reason, you need to keep the SDK and your current code compatible for as long as possible, you can remove the pound sign before specifying the version: then the transition to another major version will not be taken into account.

3. Add a `post_install` block, usually placed at the end of `Podfile`:

```ruby
post_install do |installer|
  JivoPatcher.new(installer).patch()
end

class JivoPatcher
  def initialize(installer)
    @sdkname = "JivoSDK"
    @installer = installer
  end
  
  def patch()
    libnames = collectLibNames()
    
    @installer.pods_project.targets.each do |target|
      if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
        target.build_configurations.each do |config|
          config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        end
      end
      
      target.build_configurations.each do |config|
        if libnames.include? target.to_s
          config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
          # config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
          # config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
        end
      end
    end
  end
  
  private def collectLibNames()
    depnames = Array.new
    
    @installer.pod_targets.each do |target|
      next if target.to_s != @sdkname
      depnames = collectTargetLibNames(target)
    end
    
    return depnames.uniq()
  end

  private def collectTargetLibNames(target)
    depnames = [target.to_s]
    
    target.dependent_targets.each do |subtarget|
      depnames += [subtarget.to_s] + collectTargetLibNames(subtarget)
    end
    
    return depnames
  end
end
```

> This `post_install` block adds [Module Stability](https://www.swift.org/blog/library-evolution/) support to all pods in your project. This is necessary so that the same `JivoSDK.xcframework` package can be used without rebuilding on all versions of Xcode above 13.0 (the version on which `JivoSDK.xcframework` was built). Correct operation of the **Jivo SDK** is only possible if all of its dependencies also support Module Stability.

4. Run the command in the terminal:
```bash
pod install
```



### For React Native

To install the **Jivo Mobile SDK** in a React Native project, you will need to follow all the instructions from the current section, as well as additional instructions [from here](README_en/react_setup.md#cocoapods).



# <a name="usage">How to use Jivo Mobile SDK</a>

For native projects, **Jivo Mobile SDK API** is divided into several namespaces:
- `session`

    Responsible for everything related to the communication session, such as connection and client data
- `chattingUI`

    Responsible for everything related to the visual representation of the chat on the screen
- `notifications`

    Contains methods responsible for setting up and processing PUSH notifications
- `debugging`

    Helps with SDK debugging

Each of these spaces contains methods and properties under a common area of responsibility, and each of them corresponds to a static object that can be accessed from the **Jivo SDK Mobile API**, for example:

```
JivoSDK.[namespace].[method_or_property]
```



### Sample code for displaying the SDK chat UI on the screen:

```swift
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        JivoSDK.notifications.setPushToken(data: deviceToken)
    }
}

final class ProfileViewController {
    // ...

    private func pushSupportScreen() {
        guard let container = self.navigationController else { return }
        JivoSDK.session.startUp(channelID: "abcdef", userToken: "user@example.com")
        JivoSDK.chattingUI.push(into: container)
    }

    private func presentSupportScreen() {
        JivoSDK.session.startUp(channelID: "abcdef", userToken: "user@example.com")
        JivoSDK.chattingUI.present(over: self)
    }
}
```



### For React Native

The use case for the **Jivo Mobile SDK** in a React Native project is slightly different from the native one, you can find it [here](./README_en/react_setup.md#usage).



# <a name="api">Jivo Mobile SDK API details</a>

### For native project

**Jivo Mobile SDK API: Native** – [in this document](README_en/native_api.md).

### For React Native

**Jivo Mobile SDK API: React** – [in this document](README_en/react_api.md).

