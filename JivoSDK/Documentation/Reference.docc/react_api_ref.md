# API Reference

JavaScript API

## Session

```
Jivo.setPreferredServer(server)
```
Same as ``Jivo``.``Jivo/session``.``JVSessionController/setPreferredServer(_:)``

`server` is one of possible strings:
- auto
- europe
- russia
- asia

```
Jivo.startUp(channelID, userToken)
```
Same as ``Jivo``.``Jivo/session``.``JVSessionController/setup(widgetID:clientIdentity:)``

```
Jivo.setContactInfo(info)
```
Same as ``Jivo``.``Jivo/session``.``JVSessionController/setContactInfo(_:)``

`info` is an object containing zero or more string-to-string pairs with following keys:
- name
- email
- phone
- brief

```
Jivo.setCustomData(fields)
```
Same as ``Jivo``.``Jivo/session``.``JVSessionController/setCustomData(fields:)``

`fields` is an array containing zero or more fields, each field is an object containing string-to-string pairs with following keys:
- title
- key
- content
- link

```
Jivo.shutDown()
```
Same as ``Jivo``.``Jivo/session``.``JVSessionController/shutDown()``

## Display

```
Jivo.isOnscreen(callback)
```
Fires `callback` passing an array with single boolean value of ``Jivo``.``Jivo/display``.``JVDisplayController/isOnscreen``

```
Jivo.setLocale(localeID)
```
Same as ``Jivo``.``Jivo/display``.``JVDisplayController/setLocale(_:)``

`localeID` is a locale identifier

```
Jivo.present()
```
Same as ``Jivo``.``Jivo/display``.``JVDisplayController/present(over:)`` calling with root view controller

```
Jivo.setPresentationRequestHandler(callback)
```
Sets `callback` to be called when SDK will request to display itself

## Notifications

```
Jivo.setPermissionAskingAt(moment)
```
Same as ``Jivo``.``Jivo/notifications``.``JVNotificationsController/setPermissionAsking(at:)``

`moment` is one of possible strings:
- never
- onconnect
- onappear
- onsend

```
Jivo.setPushToken(hex)
```
Same as ``Jivo``.``Jivo/notifications``.``JVNotificationsController/setPushToken(hex:)``

```
Jivo.handlePushPayload(userInfo)
```
Same as ``Jivo``.``Jivo/notifications``.``JVNotificationsController/handleIncoming(userInfo:completionHandler:)``

## Debugging

```
Jivo.setDebuggingLevel(level)
```
Same as ``Jivo``.``Jivo/debugging``.``JVDebuggingController/level``

`level` is one of possible strings:
- silent
- full

```
Jivo.archiveLogs(callback)
```
Will fire `callback` passing two arguments:
- local url of archived logs
- operation status such as "success", "failedAccessing", "failedPreparing", or "failed"
