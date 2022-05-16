# Jivo SDK API: React



### Содержание

- [Пространство имён **JivoSDK**](#namespace:JivoSDK)
    - *function startUpSession(channelID, userToken)*
    - *function updateSessionCustomData(customData)*
    - *function shutDownSession()*
    - *function isChattingUIPresented(callback)*
    - *function presentChattingUI()*
    - *function presentChattingUIWithConfig(config)*
    - *function setChattingUIDisplayRequestHandler(callback)*
    - *function removeChattingUIDisplayRequestHandler()*
    - *function setPushToken(hexString)*
    - *function handlePushRawPayload(rawPayload, callback)*
    - *function setDebuggingLevel(level)*
    - *function archiveLogs(callback)*
    - *Object: JivoSDKSessionCustomData*
    - *Object: JivoSDKChattingConfig*
    - *String: JivoSDKDebuggingLevel*
    - *String: JivoSDKArchivingStatus*



### Пространство имён <a name="namespace:JivoSDK">JivoSDK</a>



```javascript
function startUpSession(channelID, userToken)
```

Устанавливает соединение между SDK и нашими серверами, создавая новую сессию, либо возобновляя уже существующую.

- `channelID: String`
    Идентификатор вашего канала в **Jivo** (то же самое, что и `widget_id`);
- `userToken: String`
    Уникальная строка, идентифицирующая клиента чата, по которой определяется, требуется ли создать новую сессию с новым диалогом, либо восстановить уже существующую и загрузить историю начатого диалога. Генерируется на стороне интегратора **Jivo Mobile SDK**.

> Не вызывайте этот метод при отображённом на экране UI чата **Jivo SDK**.
>
> Если вам потребуется вызвать этот метод более одного раза, но с иным значением `userToken`, то перед повторным вызовом `startUp(...)` необходимо вызвать `shutDown()`.

Параметр `userToken` в последствии сохраняется в Keychain, поэтому восстановление сессии возможно и после удаления-переустановки приложения, и при смене девайса (при условии включенной синхронизации данных Keychain в iCloud).

Также, значение `userToken` передаётся в поле `"user_token"` тела запросов от [нашего Webhook API](https://www.jivo.ru/api/#webhooks).



```javascript
function updateSessionCustomData(customData)
```

Задаёт дополнительную информацию о клиенте, которая отображается оператору.

- `customData: Object? // JivoSDKSessionCustomData`
    Информация о клиенте (подробнее [здесь](#type:JivoSDKSessionCustomData))

> На данный момент реализация метода такова, что для обновления дополнительной информации о клиенте на стороне оператора вам необходимо вызвать метод `JivoSDK.startUpSession(...)` после изменения custom data.



```javascript
function shutDownSession()
```

Закрывает текущее соединение, производит очистку локальной базы данных и отправляет запрос на отписку устройства от PUSH-уведомлений для клиента сессии.

> Всегда вызывайте метод `JivoSDK.shutDownSession()` перед тем, как повторно вызвать метод `JivoSDK.startUpSession(...)` с параметром `userToken`, отличным от того, что использовался в сессии ранее.



```javascript
function isChattingUIPresented(callback)
```

Возвращает в функции обратного вызова `true`, если UI чата SDK в данный момент отображается на экране, иначе – `false`.

- `callback: (?boolean) => ()` – функция обратного вызова, принимающая результат проверки того, отображён ли UI чата SDK на экране в данный момент.



```javascript
function presentChattingUI()
```

Отображает UI чата поверх всех других UI-элементов на экране нативными средствами UIKit, используя конфигурацию UI по-умолчанию.



```javascript
function presentChattingUIWithConfig(config)
```

Отображает UI чата поверх всех других UI-элементов на экране нативными средствами UIKit, используя переданную конфигурацию UI.

- `config: Object // JivoSDKChattingConfig`
    Конфигурация UI чата (подробнее [здесь](#type:JivoSDKChattingConfig))

### 

```javascript
function setChattingUIDisplayRequestHandler(callback)
```

Задаёт функцию обратного вызова. Эта функция вызывается в тот момент, когда логика работы **Jivo Mobile SDK** подразумевает отображение UI чата на экране. Реализуйте в этом `callback` логику открытия UI чата SDK на экране.

- `callback: () => ()`
    Функция обратного вызова, запрашивающая от вас отображение UI чата SDK на экране.



```javascript
function removeChattingUIDisplayRequestHandler()
```

Удаляет из **Jivo Mobile SDK** установленную ранее функцию обратного вызова, запрашивающую от вас отображение UI чата SDK на экране.



```javascript
function setPushToken(hexString)
```

Передаёт PUSH-токен устройства в SDK в виде `String?`, ассоциируя его с клиентом сессии.

- `hexString: string`
    Шестнадцатеричная строка PUSH-токена девайса

Когда PUSH-токен устройства попадает в SDK, он ассоциируется с конкретным клиентом (который был или будет определён параметром `userToken` метода `JivoSDK.startUpSession(...)`) и отправляется на сервер **Jivo**. После того, как сервер получает токен, у него появляется возможность отправлять PUSH-уведомления на устройство.

Если PUSH-токен устройства был задан до вызова метода 
`JivoSDK.startUpSession(...)`, то он сохраняется в SDK и будет отправлен на сервер **Jivo** после установления соединения. В случае, если PUSH-токен был установлен после вызова метода `JivoSDK.startUpSession(...)`, токен будет отправлен немедленно.

Для того, чтобы отписать устройство от PUSH уведомлений для текущего клиента, вызовите метод `shutDown()`. 



```javascript
function handlePushRawPayload(rawPayload, callback)
```

Обрабатывает данные PUSH-уведомления, передаваемые в параметре типа `[AnyHashable : Any]`, и возвращает `true`, если уведомление было отправлено со стороны **Jivo**, либо `false`, если уведомление было отправлено другой системой.

В рамках реализации этого метода **Jivo Mobile SDK** определяет тип уведомления от нашей системы. Если этот тип подразумевает, что нажатие пользователя на PUSH должно сопровождаться открытием экрана чата, то будет вызвана функция обратного вызова, переданная вами в качестве параметра в функцию `setChattingUIDisplayRequestHandler(handler)`.

- `rawPayload: Object`
    Объект из тела PUSH-уведомления с его данными
- `callback: (?boolean) => ()`
    Функция обратного вызова, куда приходит результат обработки данных PUSH-уведомления



```javascript
function setDebuggingLevel(level)
```

С помощью этого свойства вы можете задать степень того, насколько подробно будет производиться логирование в SDK.

- `level: String // JivoSDKChattingConfig`
  Степень логирования в SDK (подробнее [здесь](#type:JivoSDKDebuggingLevel))



```javascript
function archiveLogs(callback)
```

Выполняет архивацию сохранённых записей логов и возвращает в функцию обратного вызова ссылку на созданный архив и статус операции.

- `callback: (url: String, status: String) => ()` 
   Функция обратного вызова, которая будет вызвана по завершению операции.
  В коллбэк будут переданы:
  -  `url: String`
     URL архива (если удалось создать)
  - `status: String // JivoSDKArchivingStatus`
     Статус операции (подробнее [здесь](#type:JivoSDKArchivingStatus))



##### Вспомогательные типы



- Объект <a name="type:JivoSDKSessionCustomData">**Object: JivoSDKSessionCustomData**</a>

    - `name: String`
        Имя клиента

    - `email: String`
        E-mail клиента 

    - `phone: String`
        Телефон клиента

    - `brief: String`
        Дополнительная информация о клиенте в произвольной форме

- Объект <a name="type:JivoSDKChattingConfig">**Object: JivoSDKChattingConfig**</a>

    - `localeIdentifier: String`
        Код региона в формате `ru_RU`, язык которого будет использоваться при локализации UI чата

    - `icon: [Object | String]`
        Иконка, отображаемая в верхнем баре над окном чата до того, как оператор подключится к диалогу. Если у оператора установлен аватар, то он заменяет собой иконку сразу после загрузки. Вы можете либо передать объект, содержащий ссылку на изображение, либо строку с указанием режима отображения:

        - `“default”`
            Будет отображена стандартная иконка с логотипом Jivo

        - `“hidden”`
            Иконка будет скрыта. Если у оператора установлен аватар, он заполнит собой пустое место. Иначе – никакое изображение показано не будет, а тексты заголовка и подзаголовка сместятся влево, заполняя собой пустое пространство.

        Если передавать параметр в виде объекта, то он обязательно должен содержать в себе поле `uri: string`, значением которого является URI для доступа к изображению. Получить такой объект можно, например, следующим образом:

     ```js
    const myImage = require('./someImage.png');
    const resolveAssetSource = require('react-native/Libraries/Image/resolveAssetSource');
    const resolvedImage = resolveAssetSource(myImage); // Объект иконки
     ```

    - `titlePlaceholder: String` 
        Текст заголовка по-умолчанию, отображаемого в верхнем баре над окном чата, до того момента, как SDK не получит имя оператора (оно заменит собой текст заголовка по-умолчанию)
    - `titleColor: String`
        Цвет заголовка, отображаемого в верхнем баре над окном чата, указывается в формате `#ABCDEF`
    - `subtitleCaption: String`
        Текст подзаголовка, отображаемого в верхнем баре над окном чата
    - `subtitleColor: String`
        Цвет подзаголовка, отображаемого в верхнем баре над окном чата, указывается в формате `#ABCDEF`
    - `inputPlaceholder: String`
        Плейсхолдер текстового поля ввода внизу окна чата
    - `activeMessage: String`
        Текст активного приглашения. Активное приглашение – это сообщение, которое автоматически отображается для новых клиентов в ленте чата слева. Если не указывать значение для данного поля, то активное приглашение показано не будет
    - `outcomingPalette: String ['green', 'blue', 'graphite']`
        Основной цвет для фона клиентских сообщений, кнопки отправки и каретки ввода текста, по умолчанию 'green'

- Перечисление <a name="type:JivoSDKDebuggingLevel">**String: JivoSDKDebuggingLevel**</a>

    - `"full"`
        Режим полного логирования
    - `"silent"`
        Логирование не ведётся

- Перечисление <a name="type:JivoSDKArchivingStatus">**String: JivoSDKArchivingStatus **</a>

    - `"success"`
        Сохранённые записи логов были успешно заархивированы, параметр замыкания типа `String` содержит ссылку на созданный архив
    - `"failedAccessing"`
        Не удалось получить доступ к файлу архива в папке `Caches`, параметр замыкания типа `String` равен `nil`
    - `"failedPreparing"`
        Не удалось подготовить содержимое архива, возможна ошибка кодировки, параметр замыкания типа `String?` равен `null`
