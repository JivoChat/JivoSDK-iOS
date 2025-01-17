# API Reference

Dart API

## Session

```
Future<void> Jivo.session.setPreferredServer(JVSessionServer server) async
```
Same as ``Jivo``.``Jivo/session``.``JVSessionController/setPreferredServer(_:)``

```
Future<void> Jivo.session.startUp({required String channelID, required String userToken}) async
```
Same as ``Jivo``.``Jivo/session``.``JVSessionController/setup(widgetID:clientIdentity:)``

```
Future<void> Jivo.session.setContactInfo({String? name, String? email, String? phone, String? brief}) async
```
Same as ``Jivo``.``Jivo/session``.``JVSessionController/setContactInfo(_:)``

```
Future<void> Jivo.session.setCustomData(List<JVSessionCustomDataField> fields) async
```
Same as ``Jivo``.``Jivo/session``.``JVSessionController/setCustomData(fields:)``

```
Future<void> Jivo.session.shutDown() async
```
Same as ``Jivo``.``Jivo/session``.``JVSessionController/shutDown()``

```
void Jivo.session.startWatchingUnreadCounter(Function watcher)
```
Same as ``Jivo``.``Jivo/session``.``JVSessionController/delegate`` -> ``JVSessionDelegate/jivoSession(updateUnreadCounter:number:)``

## Display

```
Future<bool> Jivo.display.isOnscreen async
```
Same as ``Jivo``.``Jivo/display``.``JVDisplayController/isOnscreen``

```
Future<void> Jivo.display.setLocale(Locale locale) async
```
Same as ``Jivo``.``Jivo/display``.``JVDisplayController/setLocale(_:)``

```
Future<void> Jivo.display.present() async
```
Same as ``Jivo``.``Jivo/display``.``JVDisplayController/present(over:)`` calling with root view controller

```
void Jivo.display.executeWhenAsksToAppear(Function executor)
```
Same as ``Jivo``.``Jivo/display``.``JVDisplayController/delegate`` -> ``JVDisplayDelegate/jivoDisplay(asksToAppear:)``

## Notifications

```
Future<void> Jivo.notifications.setPermissionAsking(JVNotificationsPermissionAskingMoment moment) async
```
Same as ``Jivo``.``Jivo/notifications``.``JVNotificationsController/setPermissionAsking(at:)``

## Debugging

```
Future<void> Jivo.debugging.setLevel(JVDebuggingLevel level) async
```
Same as ``Jivo``.``Jivo/debugging``.``JVDebuggingController/level``

```
Future<void> Jivo.debugging.archiveLogs({required Function completion}) async
```
Same as ``Jivo``.``Jivo/debugging``.``JVDebuggingController/archiveLogs(completion:)``
