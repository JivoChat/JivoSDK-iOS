Pod::Spec.new do |root|
    root.name = 'JivoSDK'
    root.version = '4.5.1'
    root.homepage = 'https://github.com/JivoChat'
    root.authors = { "Anton Karpushko" => "karpushko@jivosite.com", "Stan Potemkin" => "potemkin@jivosite.com" }
    root.summary = 'Jivo business chat Mobile SDK'
    root.license = 'Apache 2.0'
    root.source = { :git => 'https://github.com/JivoChat/JivoSDK-iOS.git', :tag => "v#{root.version}" }
    root.info_plist = {"CFBundleShortVersionString" => "#{root.version.version.partition('-').first}", "JVPackageVersion" => "#{root.version}"}
    root.swift_versions = ['5.5', '5.6', '5.7', '5.8', '5.9']
    root.ios.deployment_target = '12.0'
    root.default_subspec = 'SDK'

    root.script_phase = {
        :name => 'Check for an update',
        :output_files => ['/dev/null'],
        :script => <<~EOS
            jv_compare_versions() {
                local LOCAL_VER="$1"
                local LATEST_VER="$2"
                local MAX_VER=`echo "$LOCAL_VER\\n$LATEST_VER" | sort -V | tail -n 1`

                if [[ -z "$LOCAL_VER" || -z "$LATEST_VER" ]]; then
                    return
                fi

                echo "Your JivoSDK version: $LOCAL_VER"
                echo "Latest JivoSDK version: $LATEST_VER"

                if [[ "$LOCAL_VER" == "$LATEST_VER" ]]; then
                    echo "You have the latest JivoSDK version"
                elif [[ "$LOCAL_VER" != "$MAX_VER" ]]; then
                    echo "warning: Newer JivoSDK version $LATEST_VER is available (you have $LOCAL_VER)"
                fi
            }

            LOOKUP_FILE="$TARGET_TEMP_DIR/Lookup.cache"
            touch "$LOOKUP_FILE"

            LOOKUP_DATE=`cat "$LOOKUP_FILE" | cut -d ' ' -f 1`
            LOCAL_VER=`echo "#{root.version}" | sed 's/-/~/'`
            NOW_DATE=`date +'%F'`

            if [[ "$NOW_DATE" == "$LOOKUP_DATE" ]]; then
                LATEST_VER=`cat "$LOOKUP_FILE" | cut -d ' ' -f 2`
                jv_compare_versions "$LOCAL_VER" "$LATEST_VER"
            else
                LATEST_INFO=`curl --silent 'https://api.github.com/repos/JivoChat/JivoSDK-ios/releases/latest'`
                LATEST_VER=`echo "$LATEST_INFO" | grep '"name"' | sed -E -e 's/[^:]*:[^"]*"(.*)".*/\\1/' -e 's/-/~/'`
                jv_compare_versions "$LOCAL_VER" "$LATEST_VER"
                echo "$NOW_DATE $LATEST_VER" > "$LOOKUP_FILE"
            fi
        EOS
    }

    root.subspec 'SDK' do |spec|
        spec.dependency 'JFMarkdownKit', '1.2.3'
        spec.dependency 'JFEmojiPicker', '1.2'
        spec.dependency 'JFWebSocket', '2.9.5'
        spec.dependency 'JMCodingKit', '5.0.4'
        spec.dependency 'JMRepicKit', '1.0.6'
        spec.dependency 'JMTimelineKit', '4.3.5'
        spec.dependency 'JMMarkdownKit', '1.2.4'
        spec.dependency 'JMDesignKit', '1.0.0'
        spec.dependency 'JMOnetimeCalculator', '1.0.0'
        spec.dependency 'JMScalableView', '1.0.0'
        spec.dependency 'JMSidePanelKit', '1.0.0'
        spec.dependency 'TypedTextAttributes', '~> 1.4.0'
        spec.dependency 'PureParser', '~> 1.0.4'
        spec.dependency 'ReachabilitySwift', '~> 5.0'
        spec.dependency 'SwiftGraylog', '~> 1.1.1'
        spec.dependency 'SwiftDate', '~> 6.0'
        spec.dependency 'SwiftMime', '~> 1.0.0'
        spec.dependency 'KeychainSwift', '>= 20.0', '< 23.0'
        spec.dependency 'GzipSwift', '~> 5.1.1'
        spec.dependency 'SafeURL', '~> 3.0.1'
        spec.dependency 'CollectionAndTableViewCompatible', '~> 0.2.2'
        spec.dependency 'JWTDecode', '~> 2.6'
        spec.dependency 'libPhoneNumber-iOS', '~> 0.9.15'
        spec.dependency 'XCGLogger', '~> 7.0.1'

        spec.framework = 'SystemConfiguration'
        spec.source_files = 'Shared/Models', 'Shared/Models/**/*.swift', 'JivoSDK/Sources/**/*.{h,swift}', 'Shared/Sources/**/*.swift', 'Shared/Sources/Extensions/System/*.swift', 'Shared/Design/**/*.swift', 'JivoSDK/Documentation/Reference.docc/**/*'
        spec.resource = 'Shared/Models/*.xcdatamodeld', 'JivoSDK/Resources/Assets.xcassets', 'JivoSDK/Resources/Langpack/*.lproj', 'Shared/Design/*.{xcassets,ttf}'
        spec.resource_bundles = {'JivoSDK_Privacy' => ['JivoSDK/Resources/PrivacyInfo.xcprivacy']}

        spec.exclude_files = [
            'Shared/**/*Unit.swift',
            'Shared/**/*Tests.swift',
            'Shared/**/*Mock.swift',
            '**/DevicePlaybackAudioPlayer.swift',
            '**/DevicePlaybackDriver.swift',
        ]
    end
end
