# Jivo SDK API: Native



### Content

- [Namespace **JivoSDK.session**](#namespace_session)
    - *var delegate*
    - *func setPreferredServer(_:)*
    - *func startUp(channelID:userToken:)*
    - *func setClientInfo(_:)*
    - *func setCustomData(fields:)*
    - *func shutDown()*
    - *protocol JivoSDKSessionDelegate*
    - *struct JivoSDKSessionClientInfo*
    - *struct JivoSDKSessionCustomDataField*
- [Namespace **JivoSDK.chattingUI**](#namespace_chattingUI)
    - *var delegate*
    - *var isDisplaying*
    - *func push(into:)*
    - *func push(into:config:)*
    - *func place(within:)*
    - *func place(within:closeButton:config:)*
    - *func present(over:)*
    - *func present(over:config:)*
    - *protocol JivoSDKChattingUIDelegate*
    - *struct JivoSDKChattingConfig*
- [Namespace **JivoSDK.notifications**](#namespace_notifications)
    - *func setPermissionAsking(at:handler:)*
    - *func setPushToken(data:)*
    - *func setPushToken(hex:)*
    - *func handleRemoteNotification(userInfo:)*
    - *func handleNotification(_:)*
    - *func handleNotification(response:)*
- [Namespace **JivoSDK.debugging**](#namespace_debugging)
    - *var level*
    - *func archiveLogs(completion:)* 
    - *enum JivoSDKDebuggingLevel*
    - *enum JivoSDKArchivingStatus*



### Namespace <a name="namespace_session">JivoSDK.session</a>

<a name="vtable:JivoSDK.session.delegate" />

```swift
var delegate: JivoSDKSessionDelegate? { get set }
```

Delegate for handling events related to connection and client session (more details [here](#type_JivoSDKSessionDelegate)).
> At the moment, the JivoSDKSessionDelegate protocol does not contain any declarations within itself. Let us know what properties or callback methods you would like to see in it.

<a name="vtable:JivoSDK.session.delegate" />


```swift
func setPreferredServer(_ server: JivoSDKSessionServer)
```

Sets the preferred server for SDK connection to **Jivo** backend.

- `server: JivoSDKSessionServer`

    Preferred server locale:

    - `europe`
        European servers
    - `russia`
        Russian servers
    - `asia`
        Asian servers
    - `auto`
        Automatic selection

<a name="vtable:JivoSDK.session.startUp" />


```swift
func startUp(channelID: String, userToken: String)
```

Establishes a connection between the SDK and our servers, either creating a new session or resuming an existing one.

- `channelID: String`

    Your channel ID in **Jivo** (same as `widget_id`);

- `userToken: String`

    A unique string that identifies the chat client and determines whether it is necessary to create a new session with a new dialog, or restore an existing one and load the history of the initiated dialog. Generated on the side of the **Jivo Mobile SDK** integrator.

> Do not call this method with the **Jivo Mobile SDK** Chat UI displayed on the screen.
>
> If you need to call this method more than once, but with a different `userToken` value, you must call `shutDown()` before calling `startUp(...)` again.

The `userToken` parameter is subsequently stored in the Keychain, so session recovery is possible after uninstalling/reinstalling the application, and when changing the device (provided that Keychain data synchronization in iCloud is enabled).

Also, the `userToken` value is passed in the `"user_token"` field of the request body from [our Webhook API](https://www.jivochat.com/docs/overview.html#webhooks).

<a name="vtable:JivoSDK.session.setClientInfo" />

```swift
func setClientInfo(_ info: JivoSDKSessionClientInfo?)
```

Specifies additional information about the client that is displayed to the agent.

- `info: JivoSDKSessionClientInfo?`

    Client information (details [here](#type_JivoSDKSessionClientInfo))

> At the moment you need to call the `JivoSDK.session.startUp(...)` method after changing the Client Info to update additional information about the client on the agent side.

<a name="vtable:JivoSDK.session.setCustomData" />

```swift
func setCustomData(fields: [JivoSDKSessionCustomDataField])
```

Specifies additional information about the client that is displayed to the agent.

- `fields: [JivoSDKSessionCustomDataField]`

    Additional information about the client (details [here](#type_JivoSDKSessionClientInfo))

<a name="vtable:JivoSDK.session.shutDown" />

```swift
func shutDown()
```

Closes the current connection, cleans up the local database, and sends a request to unsubscribe the device from PUSH notifications to the client session.

> You should always call the `shutDown()` method before calling the `startUp(channelID:userToken:)` method again with a different `userToken` than the one used in the session before.



##### Additional types

- Protocol <a name="type_JivoSDKSessionDelegate">**JivoSDKSessionDelegate**</a>

    Implementation will come in future versions
    
- Structure <a name="type_JivoSDKSessionClientInfo">**JivoSDKSessionClientInfo**</a>

    - `name: String?`

        Client name

    - `email: String?`

        Client e-mail 

    - `phone: String?`

        Client phone number

    - `brief: String?`

        Additional information about the client in any form
    
- Structure <a name="type_JivoSDKSessionCustomDataField">**JivoSDKSessionCustomDataField**</a>

    - `title: String?`

    - `key: String?`

    - `content: String`

    - `link: String?`



### Namespace <a name="namespace_chattingUI">JivoSDK.chattingUI</a>



```swift
var delegate: JivoSDKChattingUIDelegate? { get set }
```

Sets a delegate to handle events related to the display of the chat UI on the screen (more details [here](#type_JivoSDKChattingUIDelegate)).



```swift
var isDisplaying: Bool { get }
```

Returns `true` if the view of the `UIViewController` representing the SDK chat is currently in the view hierarchy (the SDK chat UI should be displayed on the screen in this case), otherwise `false`.



```swift
func push(into navigationController: UINavigationController)
```

Adds a `ViewController` of the **Jivo Mobile SDK** chat to the stack of the passed `UINavigationController` and displays the chat on the screen with default UI settings.

- `into navigationController: UINavigationController`

  The `UINavigationController` object, on the stack of which the `ViewController` will be added, which is responsible for the chat UI. 



```swift
func push(into navigationController: UINavigationController, config: JivoSDKChattingConfig)
```

Adds the `ViewController` of the **Jivo Mobile SDK** chat to the stack of the passed `UINavigationController` and displays the chat on the screen with the specified UI settings.

- `into navigationController: UINavigationController`

    The `UINavigationController` object, on the stack of which the `ViewController` will be added, responsible for the chat UI

- `config: JivoSDKChattingConfig`
  
  Chat UI configuration (details [here](#type_JivoSDKChattingConfig))



```swift
func place(within navigationController: UINavigationController)
```

Removes the entire stack in the passed `UINavigationController` object and adds the `ViewController` responsible for the chat UI to the stack with default display settings. 

- `within navigationController: UINavigationController`

  The `UINavigationController` object, whose stack will be replaced by the ViewController responsible for the chat UI.



```swift
func place(within navigationController: UINavigationController, closeButton: JivoSDKChattingCloseButton, config: JivoSDKChattingConfig) 
```

Removes the entire stack in the passed `UINavigationController` object and adds the `ViewController` responsible for the chat UI to the stack with the given display settings.

- `within navigationController: UINavigationController`

    The `UINavigationController` object, the stack of which will be replaced by a `ViewController` responsible for the chat UI
    
- `closeButton: JivoSDKChattingCloseButton`

    Choosing an icon for the close chat button

- `config: JivoSDKChattingConfig`

  Chat UI configuration (details [here](#type_JivoSDKChattingConfig))



```swift
func present(over viewController: UIViewController)
```

Displays the chat UI modally on the screen with the default visual settings by calling the `present(_:animated:)` method on the passed `ViewController`. Runs animated.

- `over viewController: UIViewController`

  `ViewController`, on top of which the chat UI will be displayed modally



```swift
func present(over viewController: UIViewController, config: JivoSDKChattingConfig)
```

Displays the chat UI modally on the screen with the specified visual settings by calling the `present(_:animated:)` method on the passed `ViewController`. Runs animated.

- `over viewController: UIViewController`

    `ViewController`, on top of which the chat UI will be displayed modally
- `config: JivoSDKChattingConfig`

  Chat UI configuration (details [here](#type_JivoSDKChattingConfig))



##### Additional types



- Protocol <a name="type_JivoSDKChattingUIDelegate">**JivoSDKChattingUIDelegate**</a>

    - `func jivo(willAppear:)`
      
        Called before the **Jivo Mobile SDK** opens.
        
    - `func jivo(didDisappear:)`
      
        Called after the **Jivo Mobile SDK** has closed.
        
    - `func jivo(didRequestChattingUI:)`
      
        Called when the **Jivo Mobile SDK** logic needs to display the chat UI on the screen.
        
        

- Structure <a name="type_JivoSDKChattingConfig">**JivoSDKChattingConfig**</a>

    - `locale: Locale?`

        Information about the region by which the appropriate language is set for the UI chat (only those languages that are supported by the Jivo SDK are available for interface localization). The default value is `Locale.autoupdatingCurrent`

    - `useDefaultIcon: Bool` **[Only for Objective-C]**

        Specifying whether to display the agent icon by default (an image with the Jivo logo). If the parameter value is `true`, then the default icon will be displayed even if `customIcon` is specified or the agent does not have an avatar; if the value is `false`, then the icon will not be shown by default and either the image passed in the `customIcon` parameter or the agent's avatar will be displayed instead. If there is no `customIcon` and no avatar, no image will be shown in the bar, and the title and subtitle texts will shift to the left, filling the empty space. The default value is `true`

    - `customIcon: UIImage?` **[Only for Objective-C]**

        Custom agent icon before connecting, displayed in the top bar above the chat window, displayed in the top bar above the chat window. If the agent has an avatar set, then it replaces the icon passed in the `customIcon` parameter, otherwise the `customIcon` remains on the screen. Replaced with the default icon if `useDefaultIcon` is `true`. The default value is `nil`;

    - `icon: JivoSDKTitleBarIconStyle?` **[Only for Swift]**

        The mode of displaying the icon in the upper bar above the chat window before the agent connects. It accepts the following values of type `JivoSDKTitleBarIconStyle` (enumeration):

        - `default`

            Standard Jivo logo

        - `hidden`

            The icon will not be displayed. The agent's avatar, if present, will be displayed immediately after loading, if not, no image will be shown, and the title and subtitle texts will shift to the left, filling the empty space

        - `custom(UIImage)`

            Custom image passed to the associated value of the enum case

    - `titlePlaceholder: String?`

        The title text displayed in the top bar above the chat window until the SDK receives the agent's name (it will replace the `titlePlaceholder` text)). The default value is the localized string “Chat with support”

    - `titleColor: UIColor?`

        The color of the title displayed in the top bar above the chat window. The default value is a `UIColor` object containing a black/white color (depending on the applied theme)

    - `subtitleCaption: String?`

        The text of the subtitle displayed in the top bar above the chat window. The default value is the localized string “Connected 24/7!”

    - `subtitleColor: UIColor?`

        The color of the subtitle displayed in the top bar above the chat window. The default value is a `UIColor` object containing a light gray color

    - `inputPlaceholder: String?`

        The placeholder of the text input field at the bottom of the chat window. The default value is the localized string “Type your message”

    - `inputPrefill: String?`

        Preset text in text input box

    - `activeMessage: String?`

        The text of the active invitation. An active invitation is a message that is automatically displayed to new customers in the chat feed on the left. If you pass `nil` for the property when initializing it, then the active prompt will not be shown. A message with an active invitation will only be displayed after a connection to the server has been established.

    - `offlineMessage: String?`

        Offline message text. An offline message is a message that is automatically displayed after a message sent by a customer if there are no active agents on the channel. If you pass `nil` or empty text for this field, then the offline message will be shown with standard text.
    
    - `outcomingPalette: JivoSDKChattingPaletteAlias?`
    
        The main color for the background of client messages, the submit button, and the text entry caret. Possible values: `green` (default), `blue`, `graphite`



### Namespace <a name="namespace_notifications">JivoSDK.notifications</a>

<a name="vtable:JivoSDK.notifications.delegate" />

```swift
var delegate: JivoSDKNotificationsDelegate? { get set }
```

Delegate for handling events related to notifications (details [here](#type_JivoSDKNotificationsDelegate)).

<a name="vtable:JivoSDK.notifications.setPermissionAsking" />

```swift
func setPermissionAsking(at moment: JivoSDKNotificationsPermissionAskingMoment, handler: JivoSDKNotificationsPermissionAskingHandler)
```

Specifies when the SDK should request access to PUSH notifications and determines which subsystem should handle incoming PUSH events.

- `at moment: JivoSDKNotificationsPermissionAskingMoment`
  
    The moment of requesting access to PUSH notifications
- `handler: JivoSDKNotificationsPermissionAskingHandler`
  
    PUSH subsystem event handler

Should be called before `JivoSDK.session.startUp(...)`

<a name="vtable:JivoSDK.notifications.setPushTokenData" />

```swift
func setPushToken(data: Data?)
```

Passes the device's PUSH token to the SDK as a `Data?`, associating it with the session client.

When a device's PUSH token enters the SDK, it is associated with a specific client (which has been or will be defined by the `userToken` parameter of the `startUp(channelID:userToken:)` method) and sent to the **Jivo** server. After the server receives the token, it has the ability to send PUSH notifications to the device.

If the device's PUSH token was set before the method `startUp(channelID:userToken:)` was called
then it is stored in the SDK and will be sent to the **Jivo** server after the connection is established. In case the PUSH token was set after calling the `startUp(channelID:userToken:)` method, the token will be sent immediately.

To unsubscribe a device from PUSH notifications for the current client, call the `shutDown()` method.

<a name="vtable:JivoSDK.notifications.setPushTokenHex" />

```swift
func setPushToken(hex: String?)
```

Passes the device's PUSH token to the SDK as a `String?`, associating it with the session client.

When a device's PUSH token enters the SDK, it is associated with a specific client (which has been or will be defined by the `userToken` parameter of the `JivoSDK.session.startUp(...)` method) and sent to the **Jivo** server. After the server receives the token, it has the ability to send PUSH notifications to the device.

If the device's PUSH token was set before the method `JivoSDK.session.startUp(...)` was called
then it is stored in the SDK and will be sent to the **Jivo** server after the connection is established. If the PUSH token was set after calling the `JivoSDK.session.startUp(...)` method, the token will be sent immediately.

To unsubscribe a device from PUSH notifications for the current client, call the `shutDown()` method. 

> The PUSH token is not saved in the SDK between application launches, so this method must be called every time, including re-authorizing

<a name="vtable:JivoSDK.notifications.handleRemoteNotification" />

```swift
func handleRemoteNotification(userInfo: [AnyHashable : Any]) -> Bool
```
> Use this method if you are handling PUSH notifications using the `UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` method and do not use the `UserNotifications` framework methods for that.

Processes the data of a PUSH notification passed as a parameter of type `[AnyHashable : Any]` and returns `true` if the notification was sent by **Jivo**, or `false` if the notification was sent by another system.

As part of the implementation of this method, the **Jivo Mobile SDK** determines the type of notification from our system. If this type implies that the user pressing PUSH should be followed by opening the chat screen, then the `jivo(didRequestChattingUI:)` method of `JivoSDKChattingUI.delegate` will be called, asking you to display the SDK chat UI on the screen.

- `containingUserInfo userInfo: [AnyHashable : Any]`

  Dictionary with data from the body of the PUSH notification.

> The method is designed to pass incoming PUSH notifications to it



```swift
func handleNotification(_ notification: UNNotification) -> Bool
```

> Use this method if you are handling push notifications using the `UserNotifications` framework methods.
>
> Call this method when the `UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:)` method you implemented from the `UserNotifications` framework fires.

Processes the PUSH notification data passed in the `UNNotification` type parameter and returns `true` if the notification was sent by **Jivo**, or `false` if the notification was sent by another system.

- `notification: UNNotification`

  The incoming notification object.



```swift
func handleNotification(response: UNNotificationResponse) -> Bool
```

> Use this method if you are handling PUSH notifications using the `UserNotifications` framework methods.
>
> Call this method when the `UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)` method you implemented from the `UserNotifications` framework fires.

Processes the data of a PUSH notification on user interaction with it and returns `true` if the notification was sent by **Jivo**, or `false` if the notification was sent by another system.

As part of the implementation of this method, the **Jivo Mobile SDK** determines the type of notification from our system. If this type implies that the user pressing PUSH should be followed by opening the chat screen, then the `jivo(didRequestChattingUI:)` method of `JivoSDKChattingUI.delegate` will be called, asking you to display the SDK chat UI on the screen.

- `response: UNNotificationResponse`

  The result of user interaction with the notification.

> The method is designed to pass incoming PUSH notifications to it



##### Additional types



- Protocol <a name="type_JivoSDKNotificationsDelegate">**JivoSDKNotificationsDelegate**</a>

    - `func jivo(needAccessToNotifications:proceedBlock:)`

        Called before the **Jivo Mobile SDK** requests access to push notifications: can be used to display your own UI by calling `proceedBlock()` when ready to show the permission request.



### Namespace <a name="namespace_debugging">JivoSDK.debugging</a>



```swift
var level: JivoSDKDebuggingLevel { get set }
```

Using this property, you can set the level of logging verbosity in the SDK (details [here](#type_JivoSDKDebuggingLevel)).



```swift
func archiveLogs(completion: @escaping (URL?, JivoSDKArchivingStatus) -> Void)
```

Performs archiving of saved log entries and returns in the completion block a link to the created archive and the status of the operation.

- `completion: @escaping (URL?, JivoSDKArchivingStatus) -> Void`

    A closure to be called when the operation completes. The URL will be passed to the block (if the archive was successfully created) and the status of the result of the operation (more details [here](#type_JivoSDKArchivingStatus)).

> May produce an empty file if the `JivoSDK.debugging.level` parameter has been set to `silent`



##### Additional types



- Enumeration <a name="type_JivoSDKNotificationsPermissionAskingMoment">**JivoSDKNotificationsPermissionAskingMoment**</a>

    - `never`

      Never ask for access to notifications
    - `onConnect`

      Request access to notifications when SDK connects to **Jivo** servers by calling `JivoSDK.session.startUp(...)`
    - `onAppear`

      Request access to notifications when the SDK window is displayed on the screen
    - `onSend`
      
        Request access to notifications when a user posts a message to a conversation

- Enumeration <a name="type_JivoSDKNotificationsPermissionAskingHandler">**JivoSDKNotificationsPermissionAskingHandler**</a>

    - `sdk`
      
        The SDK subsystem should handle PUSH events
    - `current`
      
        PUSH events should be handled by the subsystem that is currently assigned for this
    
- Enumeration <a name="type_JivoSDKDebuggingLevel">**JivoSDKDebuggingLevel**</a>

    - `full`

        Full logging mode

    - `silent`

        No ligging
        

- Enumeration <a name="type_JivoSDKArchivingStatus">**JivoSDKArchivingStatus**</a>

    - `success`

        The saved log entries were successfully archived, the `URL?` closure parameter contains a link to the created archive

    - `failedAccessing`

        Unable to access archive file in `Caches` folder, `URL?` closure parameter is `nil`

    - `failedPreparing`

        Failed to prepare archive content, possible encoding error, `URL?` closure parameter is `nil`
