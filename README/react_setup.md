# Jivo Mobile SDK for iOS: дополнительная настройка для React Native проекта
Эта инструкция является дополнением к [основной инструкции](../README.md).
Иными словами, сначала нужно выполнить шаги основной инструкции, а затем дополнительно выполнить шаги, описанные ниже.

- [Конфигурация CocoaPods](#cocoapods)
- [Использование](#usage)



## <a name="cocoapods">Конфигурация CocoaPods</a>

1. Установите плагин [`cocoapods-user-defined-build-types`](https://github.com/joncardasis/cocoapods-user-defined-build-types).
   Для этого:

     - Выполните в терминале следующую команду:

   ```bash
   gem install cocoapods-user-defined-build-types
   ```

     - Укажите плагин в `Gemfile`:

       ```ruby
       gem 'cocoapods-user-defined-build-types'
       ```
     - Укажите и активируйте плагин в `Podfile` вашего проекта Xcode, который обычно расположен в папке `ios`:

       ```ruby
       plugin 'cocoapods-user-defined-build-types' # укажите плагин
       enable_user_defined_build_types! # активируйте его
       
       target 'YourAwesomeApp' do  
         ...
       end
       ```

   > Плагин `cocoapods-user-defined-build-types` необходим по следующей причине. CocoaPods из коробки не позволяет настроить тип сборки (статическая или динамическая библиотека/фреймворк) отдельно для каждой зависимости, указанной в `Podfile`. Вместо этого можно лишь указать тип сборки сразу для всех зависимостей с помощью директивы `use_frameworks!`.
   >
   > В нашем случае в `Podfile` обязательно должны быть перечислены зависимости React Native (например, `React`), некоторые из которых являются статическими фреймворками. Также нам нужно указать зависимость `JivoSDK`, которая является динамическим фреймворком.
   >
   > Так как в нашем Podfile должны быть указаны одновременно и статические, и динамические зависимости, мы не можем использовать директиву `use_frameworks!`, и нам нужен способ настраивать тип сборки отдельно для каждой зависимости. Этот способ нам предоставляет плагин `cocoapods-user-defined-build-types`.

2. Укажите в Podfile для зависимости **JivoSDK** тип сборки `dynamic_framework`:
    ```ruby
    target 'YourAwesomeApp' do
      pod 'JivoSDK', ‘~> 2.1’, :build_type => :dynamic_framework
      ...
    end
    ```

4. Динамическое связывание может привести к проблемам линковки, если у основного проекта или его зависимостей настроены разные `Deployment Target`; поэтому нужно дополнить `post_install` блок в Podfile установкой еще одного параметра `IPHONEOS_DEPLOYMENT_TARGET`, чтобы получилось примерно так:
    ```ruby
    post_install do |installer| 
      installer.pods_project.targets.each do |target| 
        target.build_configurations.each do |config| 
          config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '[Версия iOS, указанная как ваш основной Deployment Target]'
        end 
      end 
    end
    ```

    Посмотреть, какая версия iOS указана в качестве основного `Deployment Target`, можно в настройках основного таргета:

![](./Resources/react_setup_1.png)

5. Находясь в директории, где находится `Podfile`, выполните в терминале команду:
    ```bash
    pod install
    ```

6. Добавьте в проект Xcode файлы `JivoSDKModule.h` и `JivoSDKModule.m`, которые находятся в [репозитории Jivo Mobile SDK](https://github.com/JivoChat/JivoSDK-iOS) по пути `ReactNativeModule/Native`:

    ![](./Resources/react_setup_2.png)

    ![](./Resources/react_setup_3.png)

    > <u>Не забудьте отметить чекбокс</u> `“Copy items if needed”`

7. Добавьте в проект React Native файл `JivoSDKModule.js`, рапсполагающийся в [репозитории Jivo Mobile SDK](https://github.com/JivoChat/JivoSDK-iOS) по пути `ReactNativeModule/JivoSDKModule.js`.



## <a name="usage">Использование</a>

[**Jivo Mobile SDK API: React**](react_api.md) содержит набор методов аналогичный по функциональности тому набору методов и свойств, что представлен в [**Jivo Mobile SDK API: Native**](native_api.md). Отличие состоит лишь в их именах и способе получения к ним доступа:

```
JivoSDK.[вызываемый_метод];
```

Выполнение всех операций внутри вызываемых методов происходит асинхронно. Для методов, предполагающих возвращение результата выполнения, используется передача функции обратного вызова в качестве параметра.

Методы принимают параметры строго определённого типа. Если тип переданных в метод данных не совпадает с ожидаемым, в консоли для отладки React Native приложения будет появляться соответствующее предупреждение.

Для того, чтобы получить доступ к модулю **JivoSDK** в JavaScript, вам необходимо импортировать этот модуль:

```js
import JivoSDK from '[путь к директории, в которой находится JivoSDKModule.js]/JivoSDKModule';
```

Пример кода для отображения UI чата SDK на экране:

```javascript
import JivoSDK from './JivoSDKModule';

const JivoSDKButton = () => {
  const myImage = require('./someImage.png');
  const resolveAssetSource = require('react-native/Libraries/Image/resolveAssetSource');
  const resolvedImage = resolveAssetSource(myImage);

  const onPress = () => {
    JivoSDK.startUpSession("ABCD12345", "some_token");
    JivoSDK.presentChattingUIWithConfig({
      "localeIdentifier": "ru_RU",
      "icon": resolvedImage,
      "titlePlaceholder": "Some title placeholder",
      "subtitleCaption": "Some subtitle caption",
      "inputPlaceholder": "Some input placeholder",
      "titleColor": "#AA33FF",
      "subtitleColor": "#CC2211",
    });
  };

  return (
    <Button
      title="Present Jivo SDK screen"
      color="#841584"
      onPress={onPress}
    />
  );
}

const App: () => Node = () => {
  const backgroundStyle = {
    backgroundColor: "#000000",
  };

  return (
    <SafeAreaView style={backgroundStyle}>
      <StatusBar barStyle='light-content' />
      <JivoSDKButton />
    </SafeAreaView>
  );
};
```

