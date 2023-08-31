# Link to SDK

Using CocoaPods

## Repos

Specify the following sources at the beginning of your `Podfile`:

```ruby
source 'https://github.com/cocoapods/specs' 
source 'https://github.com/jivochat/cocoapods-repo'
```

## Dependency

Add SDK as dependency into your `ios/Podfile`:
```ruby
pod 'JivoSDK'
```

In case you have your project created via standard Flutter template, your resulting directive might look as following:
```ruby
target 'Runner' do
    use_frameworks!
    use_modular_headers!

    flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
    pod 'JivoSDK'
  
    target 'RunnerTests' do
        inherit! :search_paths
    end
end
```
