source 'https://cdn.cocoapods.org/'

install! 'cocoapods',
  :disable_input_output_paths => true,
  :generate_multiple_pod_projects => true

platform :ios, '10.0'
#use_frameworks!
use_frameworks! :linkage => :static

## ignore all warnings from all dependencies
#inhibit_all_warnings!

#workspace 'HUD.xcworkspace'

target 'HUD_Example' do
  pod 'HUD', :path => './'

  target 'HUD_Tests' do
    inherit! :search_paths
    
  end
end

#pre_install do |installer|
#  dynamicFrameworks = Array['Kingfisher']
#  installer.pod_targets.each do |pod|
#    if dynamicFrameworks.include?(pod.name) and pod.build_as_static_framework?
#      def pod.build_as_static_framework?
#        false
#      end
#      def pod.build_as_dynamic_framework?
#        true
#      end
#    end
#  end
#end

#post_install do |installer|
#  installer.pods_project.targets.each do |target|
#    target.build_configurations.each do |config|
#      config.build_settings['ENABLE_BITCODE'] = 'YES'
#      config.build_settings['STRIP_INSTALLED_PRODUCT'] = 'YES'
#      config.build_settings['SWIFT_COMPILATION_MODE'] = 'wholemodule'
#      config.build_settings['SWIFT_VERSION'] = '5.0'
#      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '10.0'
#      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
#
#      if config.name == 'Debug'
#        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
#        config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
#        config.build_settings['COPY_PHASE_STRIP'] = 'NO'
#        config.build_settings['DEPLOYMENT_POSTPROCESSING'] = 'NO'
##        config.build_settings['GCC_SYMBOLS_PRIVATE_EXTERN'] = 'NO'
#        config.build_settings['GCC_GENERATE_DEBUGGING_SYMBOLS'] = 'YES'
#      else
#        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Osize'
#        config.build_settings['GCC_OPTIMIZATION_LEVEL'] = 's'
#        config.build_settings['COPY_PHASE_STRIP'] = 'YES'
#        config.build_settings['DEPLOYMENT_POSTPROCESSING'] = 'YES'
##        config.build_settings['GCC_SYMBOLS_PRIVATE_EXTERN'] = 'YES'
#        config.build_settings['GCC_GENERATE_DEBUGGING_SYMBOLS'] = 'NO'
#      end
#    end
#  end
#end
