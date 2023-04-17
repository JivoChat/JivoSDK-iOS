source 'https://github.com/CocoaPods/Specs.git' 
source 'https://github.com/JivoChat/JMSpecsRepo.git'

use_frameworks!

target :YourTargetName do
  pod 'JivoSDK'
end

post_install do |installer|
  JivoPatcher.new(installer).patch()
end

class JivoPatcher
  def initialize(installer)
    @sdkname = "JivoSDK"
    @installer = installer
  end
  
  def patch()
    libnames = collectLibNames()
    
    @installer.pods_project.targets.each do |target|
      if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
        target.build_configurations.each do |config|
          config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        end
      end
      
      target.build_configurations.each do |config|
        if libnames.include? target.to_s
          config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
          # config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
          # config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
        end
      end
    end
  end
  
  private def collectLibNames()
    depnames = Array.new
    
    @installer.pod_targets.each do |target|
      next if target.to_s != @sdkname
      depnames = collectTargetLibNames(target)
    end
    
    return depnames.uniq()
  end

  private def collectTargetLibNames(target)
    depnames = [target.to_s]
    
    target.dependent_targets.each do |subtarget|
      depnames += [subtarget.to_s] + collectTargetLibNames(subtarget)
    end
    
    return depnames
  end
end
