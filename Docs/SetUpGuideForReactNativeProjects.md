# **Jivo Mobile SDK для iOS (beta)**
## Документация для React Native проектов

В этом документе содержатся некоторые разделы основного документа, адаптированные под интеграцию Jivo SDK в React Native проекты. Остальные разделы, не имеющие адаптации здесь, сохраняют свою актуальность и для React Native проектов.

## Установка

### CocoaPods

#### Требования

Для установки Jivo SDK в свой проект Xcode вам потребуется:
- Xcode 12.0 или новее;
- CocoaPods 1.10.0 или новее (проверить версию CocoaPods можно, выполнив следующую команду в терминале: `$ pod --version`); 
- настроить deployment target в проекте на iOS версии 11.0 или более новую.
 
> Также вам необходим проект Xcode, в который интегрирован UI приложения на React Native и для которого посредством CocoaPods установлены модули React. Обычно такой проект Xcode уже сгенерирован и находится в директории ios/. Если такой проект отсутствует, вы можете создать его, опираясь на [эту документацию](https://reactnative.dev/docs/integration-with-existing-apps).

#### Шаги установки
1. Установите плагин `cocoapods-user-defined-build-types` для CocoaPods.

   Для этого:
     - выполните в терминале следующую команду:

   ```bash
   $ gem install cocoapods-user-defined-build-types
   ```

     - откройте Xcode проект вашего приложения на React Native, расположенный в: `ios/YourAwesomeApp.xcworkspace`
     - Укажите и активируйте плагин в Podfile вашего Xcode проекта:

   ```ruby
   plugin 'cocoapods-user-defined-build-types' # укажите плагин
   enable_user_defined_build_types! # активируйте его

   target 'YourAwesomeApp' do  
     ...
   end
   ```

   > Плагин cocoapods-user-defined-build-types необходим по следующей причине. CocoaPods из коробки не позволяет настроить тип сборки (статическая или динамическая библиотека/фреймворк) отдельно для каждой зависимости, указанной в Podfile. Вместо этого можно лишь указать тип сборки сразу для всех зависимостей с помощью директивы use_frameworks!. В нашем случае в Podfile обязательно должны быть перечислены зависимости React Native (например, React), некоторые из которых являются статическими фреймворками. Также нам нужно указать зависимость JivoSDK, которая является динамическим фреймворком.

   > Так как в нашем Podfile должны быть указаны одновременно и статические, и динамические зависимости, мы не можем использовать директиву use_frameworks! и нам нужен способ настраивать тип сборки отдельно для каждой зависимости. Этот способ нам предоставляет плагин cocoapods-user-defined-build-types.

2. Укажите JivoSDK как зависимость в вашем Podfile, а также укажите для фреймворка тип сборки – dynamic_framework:

```ruby
target 'YourAwesomeApp' do
  pod 'JivoSDK', ‘~> 1.4’, :build_type => :dynamic_framework
  ...
end
```

3. Укажите в Podfile своего проекта следующие источники для pod'ов: 

```ruby
source 'https://github.com/CocoaPods/Specs.git' 
source 'https://github.com/JivoChat/JMSpecsRepo.git' 
```

4. Добавьте post-install блок в свой Podfile и пропишите в блоке версию iOS, указанную как основной deployment target:

```ruby
post_install do |installer| 
  installer.pods_project.targets.each do |target| 
    target.build_configurations.each do |config| 
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      if target.name == 'libPhoneNumber-iOS' || target.name == 'BABFrameObservingInputAccessoryView' || target.name == 'SDWebImage'
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = [Версия iOS, указанная как основной deployment target]
      end
    end 
  end 
end
```

> Блок post-install добавляет поддержку module stability для всех pod'ов в вашем проекте. Это необходимо для того, чтобы один и тот же пакет JivoSDK.xcframework можно было использовать, не пересобирая на всех версиях Xcode выше 12.0 (версия, на которой JivoSDK.xcframework был собран). Корректная работа JivoSDK возможна только в том случае, если все его зависимости также будут поддерживать module stability.

Посмотреть, какая версия iOS указана в качестве основного deployment target, можно в настройках основного таргета:

![](https://drive.google.com/uc?id=1SZvpuRFmZ6jXs3M0ry4ftsoM1yXRr3Uo)

5. Находясь в директории `ios/` выполните в терминале команду:

```bash
$ pod install
```

6. Добавьте в проект Xcode файлы `JivoSDKModule.h` и `JivoSDKModule.m`, которые находятся в репозитории JivoSDK по пути `ReactNativeModule/Native`, как показано на скриншотах:

![](https://drive.google.com/uc?id=1KE20XzyIYmGFeob0vMxueFLv_NF-KjRW)

![](https://drive.google.com/uc?id=1XlBIK2VdcFBhp7WS6njwn-g-3eTwh7pI)

   `Не забудьте отметить чекбокс “Copy items if needed”!`

7. Добавьте в свой React Native проект файл `JivoSDKModule.js`, рпсполагающийся в репозитории JivoSDK по пути `ReactNativeModule/JivoSDKModule.js`.

## Использование

Jivo SDK JavaScript API содержит набор методов аналогичный по функциональности тому набору методов и свойств, что представлен в Jivo SDK Swift/Objective-C API. Отличие состоит лишь в их именах и способе получения к ним доступа:

```
JivoSDK.[вызываемый метод];
```

Выполнение всех операций внутри вызываемых методов происходит асинхронно. Для методов, предполагающих возвращение результата выполнения, используется передача функции обратного вызова в качестве параметра.

Методы принимают параметры строго определённого типа. Если тип переданных в метод данных не совпадает с ожидаемым, в консоли для отладки React Native приложения будет появляться соответствующее предупреждение.

Для того, чтобы получить доступ к модулю JivoSDK в JavaScript, вам необходимо импортировать этот модуль:

```js
import JivoSDK from '[путь к директории, в которой находится JivoSDKModule.js]/JivoSDKModule';
```

Пример кода для отображения UI чата SDK на экране:

```js
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

## Описание методов

Описание методов, составляющих Jivo SDK JavaScript API, вы можете найти [здесь](https://github.com/JivoChat/JivoSDK-iOS/blob/develop/Docs/JivoSDKJavaScriptAPIReference.md#описание-функций-jivo-sdk-javascript-api).

