# Configure a project powered by React Native

<!--Summary-->

## Overview

This manual is in addition to the <doc:setup_project_native> page.
In other words, you must first follow the steps of the main manual, and then additionally follow the steps described below.

## #1: Plugin cocoapods-user-defined-build-types

Install plugin [cocoapods-user-defined-build-types](https://github.com/joncardasis/cocoapods-user-defined-build-types), to do this:
- Run the following command in the terminal
  ```sh
  gem install cocoapods-user-defined-build-types
  ```
- Specify plugin in `Gemfile`:
  ```ruby
  gem 'cocoapods-user-defined-build-types'
  ```
- Specify and activate the plugin in the `Podfile` of your Xcode project, which is usually located in the `ios` folder:
  ```ruby
  plugin 'cocoapods-user-defined-build-types' # specify the plugin
  enable_user_defined_build_types! # activate it
  ```

> Note: The `cocoapods-user-defined-build-types` plugin is required for the following reason. CocoaPods out of the box does not allow you to configure the build type (static or dynamic library / framework) separately for each dependency specified in the `Podfile`. Instead, you can only specify the build type for all dependencies at once using the `use_frameworks!` directive.
>
> In our case, `Podfile` must necessarily list React Native dependencies (for example, `React`), some of which are static frameworks. We also need to specify the `JivoSDK` dependency, which is a dynamic framework.
>
> Since our Podfile must have both static and dynamic dependencies at the same time, we can't use the `use_frameworks!` directive, and we need a way to set the build type on a per-dependency basis. This method is provided by the `cocoapods-user-defined-build-types` plugin.

## #2: Dynamic linking for JivoSDK

Specify the `dynamic_framework` build type in the Podfile for the **JivoSDK** dependency:

```ruby
target 'YourAwesomeApp' do
  # ...
  pod 'JivoSDK', :build_type => :dynamic_framework
end
```

Then, while in the directory where `Podfile` is located, run the command in the terminal:
```sh
pod install
```

> Note: Dynamic linking can lead to linking problems if the main project or its dependencies have different `Deployment Target` settings; so you need to add another `IPHONEOS_DEPLOYMENT_TARGET` to the `post_install` block in the Podfile to match your 'Deployment Target'

> Tip: You can see which version of iOS is specified as the main `Deployment Target` in the settings of the main target:

![](react_setup_1)

## #3: Import the JivoSDKModule

Add the `JivoSDKModule.h` and `JivoSDKModule.m` files from the [Jivo Mobile SDK repository](https://github.com/JivoChat/JivoSDK-iOS) under the path `React Native Module/Native` to your Xcode project:

![](react_setup_3)

> Important: _Don't forget to check the checkbox_ “Copy items if needed”

Then, add the `JivoSDKModule.js` file to the React Native project, located in the [Jivo Mobile SDK repository](https://github.com/JivoChat/JivoSDK-iOS) under the path `ReactNativeModule/JivoSDKModule.js`.

> Note: Please keep JivoSDKModule.js file up-to-date alongwith JivoSDK updates
