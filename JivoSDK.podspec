Pod::Spec.new do |spec|
  spec.name         = 'JivoSDK'
  spec.version      = '2.0.0'
  
  spec.homepage     = 'https://github.com/JivoChat'
  spec.authors      = { "Anton Karpushko" => "karpushko@jivosite.com", "Stan Potemkin" => "potemkin@jivosite.com" }
  spec.summary      = 'Jivo business chat mobile SDK'

  spec.ios.deployment_target  = '11.0'

  spec.swift_version = "5.1"

  spec.source       = { :git => "https://github.com/JivoChat/JivoSDK-iOS.git", :tag => "#{spec.version}" }
  # spec.source       = { :git => "" }
  spec.ios.vendored_frameworks = 'Products/JivoSDK.xcframework'
  spec.resource_bundles = { 'JivoSDK' => ['Resources/Assets.xcassets', 'Resources/*.lproj'] }
  # spec.source_files = 'JivoSDK/**/*.{h,swift}', 'SharedSources/**/*.swift'
  # spec.resource    = 'JivoSDK/Assets.xcassets', 'JivoSDK/*.lproj'

  spec.info_plist = {
    "CFBundleShortVersionString" => "#{spec.version}"
  }

  spec.framework    = 'SystemConfiguration'

# Fork dependencies
  spec.dependency      'JFMarkdownKit', '1.2.2'
  spec.dependency      'JFImagePicker', '4.0.3'
  spec.dependency      'JFEmojiPicker', '1.2'
  spec.dependency      'JFFontello/Entypo', '1.5'
  spec.dependency      'JFWebSocket', '2.9'
  spec.dependency      'JFXCGLogger', '5.1.3'
  # spec.dependency      'JFAudioPlayer', '0.0.6'

# CocoaPods specs repo dependencies
  spec.dependency      'TypedTextAttributes'
  spec.dependency      'PureParser'
  spec.dependency      'ReachabilitySwift'
  spec.dependency      'Realm'
  spec.dependency      'RealmSwift'
  spec.dependency      'BABFrameObservingInputAccessoryView'
  spec.dependency      'SwiftGraylog'
  spec.dependency      'SwiftDate'
  spec.dependency      'SwiftMime'
  spec.dependency      'KeychainSwift'
  spec.dependency      'GzipSwift'
  spec.dependency      'SafeURL'
  spec.dependency      'CollectionAndTableViewCompatible'

# JMSpecsRepo dependencies
  spec.dependency      'JMShared', '4.0.0-dev.1'
  spec.dependency      'JMCodingKit', '5.0.2'
  spec.dependency      'JMRepicKit', '~> 1.0.3'
  spec.dependency      'JMTimelineKit', '3.1.2'
  spec.dependency      'JMMarkdownKit', '1.1.2'
  spec.dependency      'JMDesignKit', '1.0.0'
  spec.dependency      'JMOnetimeCalculator', '1.0.0'
  spec.dependency      'JMScalableView', '1.0.0'
  spec.dependency      'JMSidePanelKit', '1.0.0'

  spec.exclude_files = [
    'JivoSDK/Info.plist',
    'SharedSources/Models/Message/Message+Access.swift',
    'SharedSources/ChatTimelineFactory.swift',
    'SharedSources/Managers/CommonProto.swift',
    'SharedSources/Managers/CommonSubStorage.swift',
    'SharedSources/Services/ChatCacheService/ChatCacheTypes.swift',
    'SharedSources/Services/ChatCacheService/ChatCacheService.swift',
    'SharedSources/Services/MentioningService/MentioningService.swift',
    'SharedSources/Services/TypingCacheService/TypingCacheService.swift',
    'SharedSources/Services/SystemMessagingService/SystemMessagingService.swift',
    'SharedSources/Modules/Chat/Timeline/ChatTimelineProvider.swift',
    'SharedSources/**/*Unit.swift',
    '**/ChatSubStorageTests.swift',
    '**/DevicePlaybackAudioPlayer.swift',
    '**/DevicePlaybackDriver.swift'
  ]

end
