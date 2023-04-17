Pod::Spec.new do |root|
  root.name = 'JivoFoundation'
  root.version = '4.0.0'
  root.homepage = 'https://github.com/JivoChat'
  root.authors = { "Stan Potemkin" => "potemkin@jivosite.com" }
  root.summary = 'Jivo Database'
  root.source = { :git => "" }
  root.info_plist = {"CFBundleShortVersionString" => "#{root.version}"}
  root.swift_version = "5.5"
  root.ios.deployment_target = '11.0'

  root.subspec 'Extensions' do |spec|
    spec.source_files = 'Shared/Sources/Extensions/System/*.swift'
  end

  root.subspec 'Tools' do |spec|
    spec.dependency 'PureParser'
    spec.source_files = 'Shared/Sources/Tools/BroadcastTool', 'Shared/Sources/Tools/PureParserTool'
    spec.exclude_files = ['**/*Unit.swift']
  end

  root.subspec 'Design' do |spec|
    spec.dependency 'JivoFoundation/Tools'
    spec.dependency 'JivoFoundation/Extensions'
    spec.source_files = 'Shared/Design/**/*.swift'
    spec.resources = ['Shared/Design/*.{xcassets,ttf}']
  end

  root.subspec 'Database' do |spec|
    spec.ios.deployment_target = '11.0'
    spec.framework = 'AVFoundation'
    spec.dependency 'JMCodingKit', '5.0.2'
    spec.dependency 'JMRepicKit', '1.0.5'
    spec.dependency 'TypedTextAttributes'
    spec.dependency 'SafeURL'
    spec.dependency 'SwiftyNSException'
    spec.dependency 'SwiftGraylog'
    spec.dependency 'JivoFoundation/Extensions'
    spec.source_files = 'Shared/Models', 'Shared/Models/**/*.swift', 'Shared/Sources/Drivers/DatabaseDriver/**/*.swift'
    #spec.exclude_files = ['Shared/Models/**/*+Access.swift']
    spec.resource = 'Shared/Models/*.xcdatamodeld'
  end

  root.subspec 'Sources' do |spec|
    spec.ios.deployment_target = '11.0'
    spec.framework = 'AVFoundation'
    spec.dependency 'SwiftyNSException'
    spec.dependency 'JivoFoundation/Extensions'
    spec.source_files = 'Shared/Sources/Providers/LocaleProvider', 'Shared/Sources/Threading'
  end
end
