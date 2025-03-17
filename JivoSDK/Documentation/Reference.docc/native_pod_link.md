# Link to SDK using CocoaPods

Alternative option

## Repos

Specify the following sources at the beginning of your `Podfile`:

```ruby
source 'https://github.com/cocoapods/specs' 
source 'https://github.com/jivochat/cocoapods-repo'
```

## Dependency

Add SDK as dependency into your `Podfile`:
```ruby
pod 'JivoSDK'
```

In your Project Settings, add this flag to ensure some scripts to be executed correctly:
```
ENABLE_USER_SCRIPT_SANDBOXING = NO
```
