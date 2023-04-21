Pod::Spec.new do |root|
    root.name = 'JivoFoundation'
    root.version = '4.0.0-beta.3'
    root.homepage = 'https://github.com/JivoChat'
    root.authors = { "Stan Potemkin" => "potemkin@jivosite.com" }
    root.summary = 'Jivo business chat Mobile Foundation'
    root.source = { :git => 'https://github.com/JivoChat/JivoSDK-iOS.git', :tag => "v#{root.version}" }
    root.info_plist = {"CFBundleShortVersionString" => "#{root.version}"}
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
        spec.dependency 'PureParser'
        spec.source_files = 'Shared/Sources/Tools/BroadcastTool', 'Shared/Sources/Tools/PureParserTool'
        spec.exclude_files = ['**/*Unit.swift']
    end

    root.subspec 'Design' do |spec|
        spec.dependency 'JMCodingKit'
        spec.dependency 'JMRepicKit'
        spec.dependency 'SafeURL'
        spec.dependency 'SwiftyNSException'
        spec.dependency 'SwiftGraylog'
        spec.dependency 'JivoFoundation/Tools'
        spec.dependency 'JivoFoundation/Extensions'
        spec.source_files = 'Shared/Design/**/*.swift', 'Shared/Sources/Providers/LocaleProvider'
        spec.resources = ['Shared/Design/*.{xcassets,ttf}']
    end

    root.subspec 'Database' do |spec|
        spec.framework = 'AVFoundation'
        spec.dependency 'JMCodingKit', '5.0.2'
        spec.dependency 'JMRepicKit', '1.0.5'
        spec.dependency 'TypedTextAttributes'
        spec.dependency 'SafeURL'
        spec.dependency 'SwiftyNSException'
        spec.dependency 'SwiftGraylog'
        spec.dependency 'PureParser'
        spec.dependency 'JivoFoundation/Extensions'
        spec.dependency 'JivoFoundation/Design'
        spec.dependency 'JivoFoundation/Tools'
        spec.source_files = 'Shared/Models', 'Shared/Models/**/*.swift', 'Shared/Sources/Drivers/DatabaseDriver/**/*.swift', 'Shared/Sources/Threading', 'Shared/Sources/Extensions/System/*+{database,locale}.swift'
        spec.resource = 'Shared/Models/*.xcdatamodeld'
        spec.pod_target_xcconfig = {'MOMC_NO_INVERSE_RELATIONSHIP_WARNINGS' => 'YES', 'MOMC_NO_DELETE_RULE_WARNINGS' => 'YES'}
    end
end
