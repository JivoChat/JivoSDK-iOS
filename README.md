# **Jivo SDK для iOS (beta)**

![Jivo logo](/Docs/Resources/Images/jivo_logo.svg)

**Jivo SDK** – это фреймворк для интеграции бизнес-чата Jivo в ваше приложение.

Размер бинарного файла **Jivo SDK** для архитектур девайсов составляет приблизительно **4 МБ**. Размер **dSYMs** для фреймворка составляет приблизительно **8,9 МБ**.

Для работы с фреймворком вам доступны API на следующих языках (платформах):
- Swift;
- Objective-C;
- JavaScript (React Native).
#
<img src="/Docs//Resources/Images/SDK_chat_screenshot.jpeg" width=200 />

#
На данный момент Jivo SDK **НЕ** поддерживает **bitcode**.

Сейчас Jivo SDK поддерживает следующие языки:
- русский;
- английский;
- испанский;
- португальский;
- турецкий.
#
### React Native

Часть разделов этого документа имеют адаптированные версии с инструкциями по интеграции Jivo SDK в React Native проекты. Адаптированные разделы с информацией об установке, настройке и использовании Jivo SDK вы можете найти [здесь](https://github.com/JivoChat/JivoSDK-iOS/blob/master/Docs/SetUpGuideForReactNativeProjects.md#jivo-mobile-sdk-для-ios-beta); описание методов Jivo SDK JavaScript API находится [здесь](https://github.com/JivoChat/JivoSDK-iOS/blob/master/Docs/JivoSDKJavaScriptAPIReference.md#описание-функций-jivo-sdk-javascript-api). Остальные разделы этого документа, не имеющие адаптации, также актуальны и для React Native.

### Содержание
1. [Установка](https://github.com/JivoChat/JivoSDK-iOS#установка)
2. [Настройка](https://github.com/JivoChat/JivoSDK-iOS#настройка)
3. [Использование](https://github.com/JivoChat/JivoSDK-iOS#использование)
4. [Описание методов и свойств](https://github.com/JivoChat/JivoSDK-iOS#описание-методов-и-свойств)
#
## Установка

### Для нативных проектов

### CocoaPods

#### Требования

Для установки Jivo SDK в свой проект Xcode вам потребуется: 
- Xcode 12.0 или новее; 
- CocoaPods 1.10.0 или новее; 
- настроить deployment target в проекте на iOS версии 11.0 или более новую.

#### Шаги установки
1. Укажите в Podfile своего проекта следующие источники для pod'ов: 
```ruby
source 'https://github.com/CocoaPods/Specs.git' 
source 'https://github.com/JivoChat/JMSpecsRepo.git'
```

2. Укажите JivoSDK как зависимость в вашем Podfile:
```ruby
use_frameworks!

target :YourTargetName do 
  pod 'JivoSDK', ‘~> 1.5’ 
end
```

3. Добавьте post-install блок в свой Podfile:
```ruby
post_install do |installer| 
  installer.pods_project.targets.each do |target| 
    target.build_configurations.each do |config| 
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES' 
    end 
  end 
end
```

> Блок post-install добавляет поддержку [module stability](https://www.swift.org/blog/library-evolution/) для всех pod'ов в вашем проекте. Это необходимо для того, чтобы один и тот же пакет JivoSDK.xcframework можно было использовать, не пересобирая на всех версиях Xcode выше 12.0 (версия, на которой JivoSDK.xcframework был собран). Корректная работа JivoSDK возможна только в том случае, если все его зависимости также будут поддерживать module stability.

4. Выполните в терминале команду: 
```bash
$ pod install
```

### Для React Native
Инструкцию по установке Jivo SDK в React Native проект вы можете найти [здесь](https://github.com/JivoChat/JivoSDK-iOS/blob/master/Docs/SetUpGuideForReactNativeProjects.md#установка). Остальные разделы этого документа при отсутствии ссылки на адаптированную версию актуальны и для React Native проектов.
#
## Настройка

Для полноценной работы JivoSDK необходимо сделать ещё несколько вещей.

### 1. Разрешения приложения 

JivoSDK использует камеру устройства. Также ему необходим доступ к фотогалерее. Для получения необходимых разрешений добавьте соответствующие ключи в файл `Info.plist` вашего проекта:
- для получения доступа к камере устройства добавьте ключ `NSCameraUsageDescription` и значение для него; 
- для получения доступа к фото галерее на устройстве добавьте ключ `NSPhotoLibraryUsageDescription` и значение для него.

### 2. Создание канала Jivo и передача его данных в SDK

> **Для работы JivoSDK вам необходим канал типа `"Мобильное SDK"`. Его создание доступно только на аккаунтах с [корпоративной версией Jivo](https://www.jivo.ru/pricing/).**

1. В личном кабинете десктоп/веб-приложения Jivo перейдите на экран `"Управление" -> "Каналы связи"` и создайте там новый канал "Мобильное SDK"

!["Mobile SDK" channel creation](/Docs/Resources/Images/common_setup_guide_image_1.png)

2. Перейдите в настройки созданного канала "Мобильное SDK", раздел "Опции" и найдите в пункте "Параметры для Jivo Mobile SDK" значение `widget_id`. Это значение вы будете использовать при работе с Jivo SDK API везде, где будет требоваться указать `channelID`.

> **`widget_id` в настройках канала "Мобильное SDK" и `channelID` в JivoSDK Swift/Objective-C/JavaScript API – это одно и то же!**

!["Mobile SDK" channel settings](/Docs/Resources/Images/common_setup_guide_image_2.png)

### 3. Настройка PUSH-уведомлений

> PUSH-уведомления не работают в sandbox окружении, иными словами, вы не сможете проверить работу уведомлений в debug-сборке вашего приложения. Протестировать работу PUSH-уведомлений возможно только в release-сборке, загруженной в AppStore (TestFlight).

1. В настройках проекта во вкладке Signing & Capabilities добавьте новую возможность (capability) – Background Modes, и в появившемся разделе отметьте пункт Remote notifications; 
2. в той же вкладке добавьте новую возможность (capability) – Push Notifications; 
3. наши PUSH-уведомления используют локализацию на стороне клиента ([подробнее в разделе "Localize Your Alert Messages"](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification)). В теле уведомления для заголовка и сообщения PUSHа указаны ключи локализации. Добавьте в файлы локализации `Localizable.strings` вашего проекта строки для следующих ключей:
- `"JV_MESSAGE_TITLE"` – ключ заголовка PUSHа; 
- `"JV_MESSAGE"` – ключ сообщения PUSHа.

Помимо ключей в теле PUSH-уведомления мы передаём ещё и аргументы, которые вы также можете использовать при локализации текста PUSHа: 
- первый аргумент содержит имя пользователя, который отправил сообщение;
- второй аргумент содержит текст сообщения.

Вот пример того, как может выглядеть локализация текста PUSH-уведомления в файле локализации *.strings для русского языка: 
```
"JV_MESSAGE_TITLE" = "Поддержка"; 
"JV_MESSAGE" = "%1$@: %2$@"; // '%1$@' и '%2$@' - это плейсхолдеры для аргументов PUSH-уведомления
```

4. добавьте ключ для Apple Push Notifications service (APNs) в разделе `Keys` на странице своего аккаунта в [developer.apple.com](developer.apple.com) (или используйте уже существующий ключ APNs);
сохраните этот ключ – сервис [developer.apple.com](developer.apple.com) предложит вам загрузить ключ в виде файла с расширением `.p8`;

> **Создав ключ для APNs сохраните его в надёжном месте. Созданный ключ APNs можно скачать только один раз!**

5. добавьте ключ APNs в виде файла с расширением `.p8` на созданный только что канал "Мобильное SDK". Для этого перейдите в `"Управление" -> "Каналы связи" -> "Мобильное SDK" (кнопка "Настроить") -> "Настройки PUSH" -> "Загрузить сертификат P8"`.

!["Mobile SDK" channel PUSH settings](/Docs/Resources/Images/common_setup_guide_image_3.png)

Также помимо ключа APNs вам нужно будет указать:
- `key_id`; 
- `bundle_id`; 
- `team_id`.

!["Mobile SDK" channel PUSH settings – adding .p8 token](/Docs/Resources/Images/common_setup_guide_image_4.png)

> **PUSH-уведомления отправляются только тогда, когда соединение между Jivo SDK и нашим сервером закрыто.**

> **Соединение между Jivo SDK и нашим сервером разрывается, когда закрывается окно чата. После этого мы начинаем отправлять PUSH-уведомления. Таким образом, вы можете настроить отображение уведомлений от Jivo внутри вашего приложения для foreground-состояния.**
#
## Использование

### В нативных проектах 

Jivo SDK API поделено на три, условно говоря, пространства имён:
- `session` – отвечает за всё, что связано с сеансом общения клиента и оператора, например, подключение и данные клиента;
- `chattingUI` – отвечает за всё, что связано с визуальным представлением чата на экране;
- `notifications` – содержит в себе методы, отвечающие за настройку и обработку PUSH-уведомлений;
- `debugging` – отвечает за отладку SDK.

Каждое из них содержит методы и свойства, объединённые общей областью ответственности, и каждому из них соответствует статический объект, доступ к которому можно получить из JivoSDK, например:

```
JivoSDK.[пространство имён].[метод или свойство]
```

#### Пример кода для отображения UI чата SDK на экране:

```swift
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        JivoSDK.session.setPushToken(data: deviceToken)
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

### В React Native

Инструкцию по использованию Jivo SDK в React Native проекте вы можете найти [здесь](https://github.com/JivoChat/JivoSDK-iOS/blob/master/Docs/SetUpGuideForReactNativeProjects.md#использование). Остальные разделы этого документа при отсутствии ссылки на адаптированную версию актуальны и для React Native проектов.
#
## Описание методов и свойств

### Для нативных проектов

Описание методов и свойств, составляющих нативный Jivo SDK API, содержится в [этом документе](https://github.com/JivoChat/JivoSDK-iOS/blob/master/Docs/JivoSDKNativeAPIReference.md#описание-методов-и-свойтсв-jivo-sdk-swiftobjective-c-api).

### Для React Native

Описание методов, составляющих Jivo SDK JavaScript API, вы можете найти [здесь](https://github.com/JivoChat/JivoSDK-iOS/blob/master/Docs/JivoSDKJavaScriptAPIReference.md#описание-методов-jivo-sdk-javascript-api). Остальные разделы этого документа при отсутствии ссылки на адаптированную версию актуальны и для React Native проектов.

