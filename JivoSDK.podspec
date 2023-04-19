Pod::Spec.new do |root|
  root.name = 'JivoSDK'
  root.version = '4.0.0-beta.1'
  root.homepage = 'https://github.com/JivoChat'
  root.authors = { "Anton Karpushko" => "karpushko@jivosite.com", "Stan Potemkin" => "potemkin@jivosite.com" }
  root.summary = 'Jivo business chat Mobile SDK'
  root.source = { :git => 'https://github.com/JivoChat/JivoSDK-iOS.git', :tag => "v#{root.version}" }
  root.info_plist = {"CFBundleShortVersionString" => "#{root.version}"}
  root.swift_versions = ['5.5', '5.6', '5.7', '5.8']
  root.ios.deployment_target = '11.0'
  root.default_subspec = 'SDK'

  root.subspec 'SDK' do |spec|
    spec.dependency 'JivoFoundation', "#{root.version}"
    spec.dependency 'JFMarkdownKit', '1.2.2'
    spec.dependency 'JFEmojiPicker', '1.2'
    spec.dependency 'JFWebSocket', '2.9.4'
    spec.dependency 'JMCodingKit', '5.0.2'
    spec.dependency 'JMRepicKit', '1.0.5'
    spec.dependency 'JMTimelineKit', '4.2.2'
    spec.dependency 'JMMarkdownKit', '1.2.1'
    spec.dependency 'JMDesignKit', '1.0.0'
    spec.dependency 'JMOnetimeCalculator', '1.0.0'
    spec.dependency 'JMScalableView', '1.0.0'
    spec.dependency 'JMSidePanelKit', '1.0.0'
    spec.dependency 'TypedTextAttributes', '~> 1.4.0'
    spec.dependency 'PureParser', '~> 1.0.4'
    spec.dependency 'ReachabilitySwift', '~> 5.0'
    spec.dependency 'BABFrameObservingInputAccessoryView'
    spec.dependency 'SwiftGraylog', '~> 1.1.1'
    spec.dependency 'SwiftDate', '~> 6.0'
    spec.dependency 'SwiftMime', '~> 1.0.0'
    spec.dependency 'KeychainSwift', '~> 20.0'
    spec.dependency 'GzipSwift', '~> 5.1.1'
    spec.dependency 'SafeURL', '~> 3.0.1'
    spec.dependency 'CollectionAndTableViewCompatible', '~> 0.2.2'
    spec.dependency 'JWTDecode', '~> 2.6'
    spec.dependency 'libPhoneNumber-iOS', '~> 0.9.15'
    spec.dependency 'XCGLogger', '~> 7.0.1'

    spec.source_files = 'JivoSDK/Sources/**/*.{h,swift}', 'Shared/Sources/**/*.swift'
    spec.framework = 'SystemConfiguration'
    spec.resource = 'JivoSDK/Resources/Assets.xcassets', 'JivoSDK/Resources/*.lproj', 'JivoSDK/*.docc'

    spec.exclude_files = [
      'JivoSDK/Info.plist',
      'Shared/**/*Unit.swift',
      'Shared/**/*Mock.swift',
      'Shared/Sources/Drivers/DatabaseDriver',
      'Shared/Sources/Drivers/CoreDataDriver',
      'Shared/Sources/Providers/LocaleProvider',
      'Shared/Sources/Extensions/System',
      '**/ChatSubStorageTests.swift',
      '**/DevicePlaybackAudioPlayer.swift',
      '**/DevicePlaybackDriver.swift',
    ]
  end
end
