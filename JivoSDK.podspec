Pod::Spec.new do |spec|
  spec.name         = 'JivoSDK'
  spec.version      = '1.4.0'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://github.com/JivoChat'
  spec.authors      = { "Anton Karpushko" => "karpushko@jivosite.com", "Stan Potemkin" => "potemkin@jivosite.com" }
  spec.summary      = 'Jivo business chat mobile SDK'

  spec.ios.deployment_target  = '10.0'

  spec.swift_version = "5.1"
  spec.platform = :ios, "10.0"

  spec.source       = { :git => "https://github.com/JivoChat/JivoSDK.git", :tag => "#{spec.version}" }
  # spec.source       = { :git => "" }
  spec.ios.vendored_frameworks = 'Products/JivoSDK.xcframework'
  spec.resource_bundles = { 'JivoSDK' => ['Resources/Assets.xcassets', 'Resources/*.lproj'] }
  # spec.source_files = 'JivoSDK/**/*.{h,swift}', 'SharedSources/**/*.swift'
  # spec.resource    = 'JivoSDK/Assets.xcassets', 'JivoSDK/*.lproj'

  spec.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }

  spec.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }

  spec.framework    = 'SystemConfiguration'

# Fork dependencies
  spec.dependency      'JFMarkdownKit', '1.2.2'
  spec.dependency      'JFImagePicker', '4.0.2'
  spec.dependency      'JFEmojiPicker', '1.2'
  spec.dependency      'JFFontello/Entypo', '1.5'
  spec.dependency      'JFWebSocket', '2.9'
  spec.dependency      'JFXCGLogger', '5.1.3'

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
  spec.dependency      'Moya'
  spec.dependency      'KeychainSwift'
  spec.dependency      'GzipSwift'
  spec.dependency      'SafeURL'
  spec.dependency      'CollectionAndTableViewCompatible'

# JMSpecsRepo dependencies
  spec.dependency      'JMShared', '2.3.4'
  spec.dependency      'JMCodingKit', '5.0.2'
  spec.dependency      'JMRepicKit', '1.0.1'
  spec.dependency      'JMTimelineKit', '1.3.0'
  spec.dependency      'JMMarkdownKit', '1.1.2'
  spec.dependency      'JMDesignKit', '1.0.0'
  spec.dependency      'JMOnetimeCalculator', '1.0.0'
  spec.dependency      'JMScalableView', '1.0.0'
  spec.dependency      'JMSidePanelKit', '1.0.0'

  spec.exclude_files = [
    'JivoSDK/Info.plist',
    'SharedSources/**/*Unit.swift',
    '**/ChatSubStorageTests.swift'
  ]

end
