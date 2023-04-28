Pod::Spec.new do |root|
    root.name = 'JivoFoundation'
    root.version = '4.0.0-beta.15'
    root.homepage = 'https://github.com/JivoChat'
    root.authors = { "Stan Potemkin" => "potemkin@jivosite.com" }
    root.summary = 'Jivo business chat Mobile Foundation'
    root.license = 'Apache 2.0'
    root.source = { :git => 'https://github.com/JivoChat/JivoSDK-iOS.git', :tag => "v#{root.version}" }
    root.info_plist = {"CFBundleShortVersionString" => "#{root.version.version.partition('-').first}", "JVPackageVersion" => "#{root.version}"}
    root.swift_versions = ['5.5', '5.6', '5.7', '5.8']
    root.ios.deployment_target = '11.0'

    root.subspec 'Extensions' do |spec|
        spec.dependency 'JMCodingKit'
        spec.dependency 'TypedTextAttributes'
        spec.dependency 'SafeURL'
        spec.dependency 'SwiftyNSException'
        spec.dependency 'SwiftGraylog'
        spec.source_files = 'Shared/Sources/Extensions/System/*+.swift'
    end

    root.subspec 'Tools' do |spec|
        spec.dependency 'JivoFoundation/Extensions'
        spec.dependency 'JMCodingKit'
        spec.dependency 'PureParser'
        spec.source_files = 'Shared/Sources/Tools/BroadcastTool', 'Shared/Sources/Tools/PureParserTool', 'Shared/Sources/Tools/JsonPrivacyTool', 'Shared/Sources/Tools/SafeDispatchQueue', 'Shared/Sources/Tools/ScannerTool'
        spec.exclude_files = ['**/*Unit.swift']
    end

    root.subspec 'Design' do |spec|
        spec.dependency 'JivoFoundation/Tools'
        spec.dependency 'JivoFoundation/Extensions'
        spec.dependency 'JMCodingKit'
        spec.dependency 'JMRepicKit'
        spec.dependency 'SafeURL'
        spec.dependency 'SwiftyNSException'
        spec.dependency 'SwiftGraylog'
        spec.source_files = 'Shared/Design/**/*.swift' #, 'Shared/Sources/Providers/LocaleProvider'
        spec.resources = ['Shared/Design/*.{xcassets,ttf}']
    end
end
