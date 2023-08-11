# Link to SDK

Using CocoaPods

## Repos

Specify the following sources at the beginning of your `Podfile`:

```ruby
source 'https://github.com/cocoapods/specs' 
source 'https://github.com/jivochat/cocoapods-repo'
```

## Plugin

For SDK proper cooperation with React Native, you should install special plugin:
```sh
gem install cocoapods-user-defined-build-types
```

Then activate this plugin using directives in your `Podfile`:
```ruby
plugin 'cocoapods-user-defined-build-types'
enable_user_defined_build_types!
```

## Dependency

Add SDK as dynamic dependency in your `Podfile`:
```ruby
pod 'JivoSDK', :build_type => :dynamic_framework
```
