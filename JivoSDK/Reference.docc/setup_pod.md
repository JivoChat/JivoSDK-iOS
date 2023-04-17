# Install the JivoSDK

<!--Summary-->

## Overview

For the **JivoSDK** to work, you need a channel of type "Mobile SDK".
> Important: Its creation is only available in [Enterprise version of **Jivo**](https://www.jivochat.com/pricing/).

## Requirements

To install the **Jivo Mobile SDK** in your Xcode project, you will need:
- Xcode 13.0 or newer
- CocoaPods 1.10.0 or newer
- Set `Deployment Target` in project to iOS 11.0 or newer

## #1: CocoaPods Repos

Specify the following sources at the beginning of your project's `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git' 
source 'https://github.com/JivoChat/JMSpecsRepo.git'
```

## #2: Add JivoSDK

Add `JivoSDK` as a dependency in your `Podfile`

```ruby
pod 'JivoSDK'
```

> Note: When connecting the SDK this way, `pod update` will install the latest version of the SDK available.
>
> If, for some reason, you need to keep the SDK and your current code compatible for as long as possible, you can specify the version you need.

## #3: post_install

Add a `post_install` block, usually placed at the end of `Podfile`

> Note: This `post_install` block adds [Module Stability](https://www.swift.org/blog/library-evolution/) support to all pods in your project.
>
> This is necessary so that the same `JivoSDK.xcframework` package can be used without rebuilding on all versions of Xcode above 13.0 (the version on which `JivoSDK.xcframework` was built).

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

## #4: That's all

Run the command in the terminal

```sh
pod install
```
