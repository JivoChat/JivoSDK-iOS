# Описание методов и свойтсв Jivo SDK Swift/Objective-C API

## **session**
### `delegate`
Объявлено как: 

```swift
var delegate: JivoSDKSessionDelegate? { get set }
```

Устанавливает делегат для обработки событий, связанных с соединением и сессией клиента.
> На данный момент протокол JivoSDKSessionDelegate не содержит ни одного объявления внутри себя. Расскажите нам, какие свойства или методы обратного вызова вы бы хотели увидеть в нём.
#
### `startUp(channelID:userToken:)`
Объявлен как:

```swift
func startUp(channelID: String, userToken: String)
```

Устанавливает соединение между SDK и нашими серверами, создавая новую сессию, либо возобновляя уже существующую. 
> Не вызывайте этот метод при отображённом на экране UI чата Jivo SDK. 
> Всегда вызывайте метод `shutDown()` перед тем, как повторно вызвать метод `startUp(channelID:userToken:)` с параметром `userToken`, отличным от того, что использовался в сессии ранее.

**Параметры:**
- `channelID: String` – идентификатор вашего канала в Jivo (то же самое, что и `widget ID`); 
- `userToken: String` – уникальная строка, идентифицирующая клиента чата, по которой определяется, требуется ли создать новую сессию с новым диалогом, либо восстановить уже существующую и загрузить историю начатого диалога. Генерируется на стороне интегратора Jivo SDK.

`userToken` сохраняется в Keychain, поэтому восстановление сессии возможно и после удаления-переустановки приложения, и при смене девайса (при условии включенной синхронизации данных Keychain в iCloud).

Значение `userToken` передаётся в поле `“user_token”` тела запросов от [нашего Webhook API](https://www.jivo.ru/api/#webhooks).
#
### `updateCustomData(_:)`
Объявлен как:

```swift
func updateCustomData(_ data: JivoSDKSessionCustomData?)
```

Задаёт дополнительную информацию о клиенте, которая отображается оператору.

> На данный момент реализация метода такова, что для обновления дополнительной информации о клиенте на стороне оператора вам необходимо вызвать метод `startUp(channelID:userToken:)` после изменения custom data.

**Параметры:**
- `data: JivoSDKSessionCustomData?` – дополнительная информация о клиенте, содержащаяся в свойствах объекта JivoSDKSessionCustomData (задаются через инициализатор, достаточно указать только те параметры, которые вы собираетесь задать): 
  - `name: String?` – имя клиента; 
  - `email: String?` – E-mail клиента; 
  - `phone: String?` – телефон клиента; 
  - `brief: String?` – дополнительная информация о клиенте в произвольной форме. 
#
### `shutDown()`
Объявлен как:

```swift
func shutDown()
```

Закрывает текущее соединение, производит очистку локальной базы данных и отправляет запрос на отписку устройства от PUSH-уведомлений для клиента сессии.

> Всегда вызывайте метод `shutDown()` перед тем, как повторно вызвать метод `startUp(channelID:userToken:)` с параметром `userToken`, отличным от того, что использовался в сессии ранее. 
#
## **chattingUI**

### `delegate`

Объявлено как:

```swift
var delegate: JivoSDKChattingUIDelegate? { get set }
```

Устанавливает делегат для обработки событий, связанных с отображением UI чата на экране.

Протокол **`JivoSDKChattingUIDelegate`** содержит следующие методы:
- `jivoDidRequestUIDisplaying()`

   Объявлен как:
   ```swift
   func jivoDidRequestUIDisplaying()
   ```
   Вызывается, когда в соответствии с логикой работы Jivo SDK необходимо отобразить UI чата на экране.
#
### `push(into:)`
Объявлен как:

```swift
func push(into navigationController: UINavigationController)
```

Добавляет view controller чата Jivo SDK в стек переданного UINavigationController и отображает чат на экране с настройками UI по-умолчанию.

**Параметры:**
- `into navigationController: UINavigationController` – объект UINavigationController, в стек которого будет добавлен view controller, отвечающий за UI чата. 
#
### `push(into:config:)`
Объявлен как:

```swift
func push(into navigationController: UINavigationController, config: JivoSDKChattingConfig)
```

Добавляет view controller чата Jivo SDK в стек переданного `UINavigationController` и отображает чат на экране с указанными настройками UI.

**Параметры:**

- `into navigationController: UINavigationController` – объект `UINavigationController`, в стек которого будет добавлен view controller, отвечающий за UI чата;
- `config: JivoSDKChattingConfig` – конфигурация UI чата со следующими свойствами, задаваемыми через инициализатор (достаточно указать только те параметры, которые вы собираетесь изменить): 
  - `locale: Locale?` – информация о регионе, по которой для UI чата устанавливается соответствующий язык (для локализации интерфейса доступны только те, языки, которые поддерживаются Jivo SDK). Значение по-умолчанию – `Locale.autoupdatingCurrent`;
  - **(Только для Objective-C)** `useDefaultIcon: Bool` – отображать ли иконку оператора по-умолчанию (изображение с логотипом Jivo). Если значение параметра – `true`, то иконка по-умолчанию будет отображена даже в случае указания `customIcon` или отсутствия аватара у оператора; если значение – `false`, то иконка по-умолчанию показана не будет и вместо неё отобразится либо изображение, переданное в параметре `customIcon`, либо аватар оператора при его подключении. При отсутствии `customIcon` и аватара никакое изображение в баре показано не будет, а тексты заголовка и подзаголовка сместятся влево, заполняя собой пустое место. Значение по-умолчанию – `true`;
  - **(Только для Objective-C)** `customIcon: UIImage?` – кастомная иконка оператора до подключения, отображаемая в верхнем баре над окном чата, отображаемая в верхнем баре над окном чата. Если у оператора установлен аватар, то он заменяет собой иконку, переданную в параметре `customIcon`, иначе – `customIcon` продолжает оставаться на экране. Заменяется иконкой по-умолчанию, если значение `useDefaultIcon` равняется `true`. Значение по-умолчанию – `nil`;
  - **(Только для Swift)** `icon: JivoSDKTitleBarIconStyle?` – режим отображения иконки в верхнем баре над окном чата до подключения оператора. Принимает следующие значения типа `JivoSDKTitleBarIconStyle` (перечисление):
    - `default` – стандартная иконка с логотипом Jivo;
    - `hidden` – иконка не будет отображаться. Аватар оператора при наличии отобразится сразу после загрузки, при отсутствии – никакое изображение показано не будет, а тексты заголовка и подзаголовка сместятся влево, заполняя собой пустое место;
    - `custom(UIImage)` – кастомное изображение, передаваемое в associated value кейса перечисления..; 
  - `titlePlaceholder: String?` – текст заголовка , отображаемого в верхнем баре над окном чата, до того момента, как SDK не получит имя оператора (оно заменит собой текст `titlePlaceholder`)). Значение по-умолчанию – локализованная строка “Чат с поддержкой”; 
  - `titleColor: UIColor?` – цвет заголовка, отображаемого в верхнем баре над окном чата. Значение по-умолчанию – объект `UIColor`, содержащий чёрный/белый цвет (в зависимости от применённой темы); 
  - `subtitleCaption: String?` – текст подзаголовка, отображаемого в верхнем баре над окном чата. Значение по-умолчанию – локализованная строка “На связи 24/7!”; 
  - `subtitleColor: UIColor?` – цвет подзаголовка, отображаемого в верхнем баре над окном чата. Значение по-умолчанию – объект `UIColor`, содержащий светло-серый цвет; 
  - `inputPlaceholder: String?` – плейсхолдер текстового поля ввода внизу окна чата. Значение по-умолчанию – локализованная строка “Введите ваше сообщение”;
  - `activeMessage: String?` – текст активного приглашения. Активное приглашение – это сообщение, которое автоматически отображается для новых клиентов в ленте чата слева. Если при инициализации для свойства передать `nil`, то активное приглашение показано не будет. Сообщение с активным приглашением отобразится только после того, как будет установлено соединение с сервером.

#
### `place(within:)`
Объявлен как:

```swift
func place(within navigationController: UINavigationController)
```

Удаляет весь стек view controller'ов в переданном объекте `UINavigationController` и добавляет в стек view controller, отвечающий за UI чата, с настройками отображения по умолчанию. 

**Параметры:**
- `within navigationController: UINavigationController` – объект `UINavigationController`, стек которого будет заменён на view controller, отвечающий за UI чата.
#
### `place(within:config:)`
Объявлен как:

```swift
func place(within navigationController: UINavigationController, config: JivoSDKChattingConfig) 
```

Удаляет весь стек view controller'ов в переданном объекте `UINavigationController` и добавляет в стек view controller, отвечающий за UI чата, с заданными настройками отображения.

**Параметры:**
- `within navigationController: UINavigationController` – объект `UINavigationController`, стек которого будет заменён на view controller, отвечающий за UI чата; 
- `config: JivoSDKChattingConfig` – конфигурация UI чата (подробнее – в описании метода `push(into:config:)`)
#
### `present(over:)`
Объявлен как:

```swift
func present(over viewController: UIViewController)
```

Отображает модально UI чата на экране с визуальными настройками по-умолчанию, вызывая метод `present(_:animated:)` для переданного view controller. Всегда выполняется анимировано.

**Параметры:**
- `over viewController: UIViewController` – view controller, поверх которого будет модально отображаться UI чата.
#
### `present(over:config:)`
Объявлен как:

```swift
func present(over viewController: UIViewController, config: JivoSDKChattingConfig)
```

Отображает модально UI чата на экране с заданными визуальными настройками, вызывая метод `present(_:animated:)` для переданного view controller. Всегда выполняется анимировано.

**Параметры:**
- `over viewController: UIViewController` – view controller, поверх которого будет модально отображаться UI чата; 
- `config: JivoSDKChattingConfig` – конфигурация UI чата (подробнее – в описании метода `push(into:config:)`).
#
## **notifications**

### `setPushToken(data:)`
Объявлен как:

```swift
func setPushToken(data: Data?)
```

Передаёт в SDK PUSH-токен устройства в видe `Data?`, ассоциируя его с клиентом сессии.

Когда PUSH-токен устройства попадает в SDK, он ассоциируется с конкретным клиентом (который был или будет определён параметром `userToken` метода `startUp(channelID:userToken:)`) и отправляется на сервер Jivo. После того, как сервер получает токен, у него появляется возможность отправлять PUSH-уведомления на устройство.

Если PUSH-токен устройства был задан до вызова метода 
`startUp(channelID:userToken:)`, то он сохраняется в SDK и будет отправлен на сервер Jivo после установления соединения. В случае, если PUSH-токен был установлен после вызова метода `startUp(channelID:userToken:)`, токен будет отправлен немедленно.

Для того, чтобы отписать устройство от PUSH уведомлений для текущего клиента, вызовите метод `shutDown()`.
#
### `setPushToken(hex:)`
Объявлен как: 

```swift
func setPushToken(hex: String?)
```

Передаёт в SDK PUSH-токен устройства в виде `String?`, ассоциируя его с клиентом сессии.

Когда PUSH-токен устройства попадает в SDK, он ассоциируется с конкретным клиентом (который был или будет определён параметром `userToken` метода `startUp(channelID:userToken:)`) и отправляется на сервер Jivo. После того, как сервер получает токен, у него появляется возможность отправлять PUSH-уведомления на устройство.

Если PUSH-токен устройства был задан до вызова метода 
`startUp(channelID:userToken:)`, то он сохраняется в SDK и будет отправлен на сервер Jivo после установления соединения. В случае, если PUSH-токен был установлен после вызова метода `startUp(channelID:userToken:)`, токен будет отправлен немедленно.

Для того, чтобы отписать устройство от PUSH уведомлений для текущего клиента, вызовите метод `shutDown()`. 
#
### `handleRemoteNotification(containingUserInfo:)`
Объявлен как:
```swift
func handleRemoteNotification(containingUserInfo userInfo: [AnyHashable : Any]) -> Bool
```
> **Используйте этот метод, если вы обрабатываете PUSH-уведомления с помощью метода `UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` и не используете для этого методы фреймворка `UserNotifications`.**

Обрабатывает данные PUSH-уведомления, передаваемые в параметре типа `[AnyHashable : Any]`, и возвращает `true`, если уведомление было отправлено со стороны Jivo, либо `false`, если уведомление было отправлено другой системой.

В рамках реализации этого метода Jivo SDK определяет тип уведомления от нашей системы. Если этот тип подразумевает, что нажатие пользователя на PUSH должно сопровождаться открытием экрана чата, то у `JivoSDKChattingUI.delegate` будет вызван метод `jivoDidRequestUIDisplaying()`, запрашивающий от вас отображение UI чата SDK на экране.

**Параметры:**
- `containingUserInfo userInfo: [AnyHashable : Any]` – словарь с данными из тела PUSH-уведомления.
#
### `handleNotification(_:)`

Объявлен как:
```swift
func handleNotification(_ notification: UNNotification) -> Bool
```

> **Используйте этот метод, если вы обрабатываете PUSH-уведомления с помощью методов фреймворка `UserNotifications` и не используете для этого метод `UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)`.**

> **Вызывайте этот метод при срабатывании реализованного вами метода `UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:)` из фреймворка `UserNotifications`.**

Обрабатывает данные PUSH-уведомления, передаваемые в параметре типа `UNNotification`, и возвращает `true`, если уведомление было отправлено со стороны Jivo, либо `false`, если уведомление было отправлено другой системой.

**Параметры:**
- `notification: UNNotification` – объект входящего уведомления.
#
### `handleNotification(response:)`

Объявлен как:
```swift
func handleNotification(response: UNNotificationResponse) -> Bool
```

> **Используйте этот метод, если вы обрабатываете PUSH-уведомления с помощью методов фреймворка `UserNotifications` и не используете для этого метод `UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)`.**

> **Вызывайте этот метод при срабатывании реализованного вами метода `UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)` из фреймворка `UserNotifications`.**

Обрабатывает данные PUSH-уведомления при пользовательском взаимодействии с ним и возвращает `true`, если уведомление было отправлено со стороны Jivo, либо `false`, если уведомление было отправлено другой системой.

В рамках реализации этого метода Jivo SDK определяет тип уведомления от нашей системы. Если этот тип подразумевает, что нажатие пользователя на PUSH должно сопровождаться открытием экрана чата, то у `JivoSDKChattingUI.delegate` будет вызван метод `jivoDidRequestUIDisplaying()`, запрашивающий от вас отображение UI чата SDK на экране.

**Параметры:**
- `response: UNNotificationResponse` – результат пользовательского взаимодействия с уведомлением.
#
## **debugging**

### `level`
Объявлено как:

```swift
var level: JivoSDKDebuggingLevel { get set }
```

С помощью этого свойства вы можете задать степень того, насколько подробно будет производиться логирование в SDK.

Перечисление `JivoSDKDebuggingLevel` содержит следующие кейсы:
- `full` – режим полного логирования;
- `silent` – логирование не ведётся.
#
### `archiveLogs(completion:)`
Объявлен как:

```swift
func archiveLogs(completion: @escaping (URL?, JivoSDKArchivingStatus) -> Void)
```

Выполняет архивацию сохранённых записей логов и возвращает в completion-блоке ссылку на созданный архив и статус.

**Параметры:**
- `completion: @escaping (URL?, JivoSDKArchivingStatus) -> Void` – замыкание, которое будет вызвано по завершению операции. В блок будут переданы URL (если удалось создать архив) и статус результата операции.

Перечисление `JivoSDKArchivingStatus` содержит следующие кейсы:
- `success` – сохранённые записи логов были успешно заархивированы, параметр замыкания типа `URL?` содержит ссылку на созданный архив;
- `failedAccessing` – не удалось получить доступ к файлу архива в папке `Caches`, параметр замыкания типа `URL?` равен `nil`;
- `failedPreparing` – не удалось подготовить содержимое архива, возможна ошибка кодировки, параметр замыкания типа `URL?` равен `nil`.
