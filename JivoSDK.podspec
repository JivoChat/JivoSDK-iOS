Pod::Spec.new do |spec|
  spec.name         = 'JivoSDK'
  spec.version      = '3.1.0'
  
  spec.dependency      'JFMarkdownKit', '1.2.2'
  spec.dependency      'JFEmojiPicker', '1.2'
  spec.dependency      'JFWebSocket', '2.9.2'
  spec.dependency      'JMShared', '4.8.1'
  spec.dependency      'JMCodingKit', '5.0.2'
  spec.dependency      'JMRepicKit', '1.0.5'
  spec.dependency      'JMTimelineKit', '4.2.1'
  spec.dependency      'JMMarkdownKit', '1.2.1'
  spec.dependency      'JMDesignKit', '1.0.0'
  spec.dependency      'JMOnetimeCalculator', '1.0.0'
  spec.dependency      'JMScalableView', '1.0.0'
  spec.dependency      'JMSidePanelKit', '1.0.0'
  spec.dependency      'TypedTextAttributes'
  spec.dependency      'PureParser'
  spec.dependency      'ReachabilitySwift', '~> 5.0'
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

  spec.homepage     = 'https://github.com/JivoChat'
  spec.authors      = { "Anton Karpushko" => "karpushko@jivosite.com", "Stan Potemkin" => "potemkin@jivosite.com" }
  spec.summary      = 'Jivo business chat mobile SDK'
  spec.info_plist = {"CFBundleShortVersionString" => "#{spec.version}"}

  spec.source       = { :git => "https://github.com/JivoChat/JivoSDK-iOS.git", :tag => "#{spec.version}" }

  
  spec.framework    = 'SystemConfiguration'
  spec.swift_version = "5.1"
  spec.resource_bundles = { 'JivoSDK' => ['Resources/Assets.xcassets', 'Resources/*.lproj'] }
  spec.ios.vendored_frameworks = 'Products/JivoSDK.xcframework'
  spec.ios.deployment_target  = '11.0'
end
