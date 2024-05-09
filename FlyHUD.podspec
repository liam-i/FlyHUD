Pod::Spec.new do |s|
  s.name             = 'FlyHUD'
  s.version          = '1.5.12'
  s.summary          = 'A lightweight and easy-to-use HUD for iOS and tvOS apps.'
  s.description      = <<-DESC
                       FlyHUD is a lightweight and easy-to-use HUD designed to display
                        the progress and status of ongoing tasks on iOS and tvOS.
                       DESC

  s.homepage         = 'https://github.com/liam-i/FlyHUD'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Liam' => 'liam_i@163.com' }
  s.source           = { :git => 'https://github.com/liam-i/FlyHUD.git', :tag => s.version.to_s }
  s.documentation_url = 'https://liam-i.github.io/FlyHUD/main/documentation/flyhud'
  s.screenshots  = 'https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/1-6.png'
  s.social_media_url   = "https://liam-i.github.io"

  # 1.12.0: Ensure developers won't hit CocoaPods/CocoaPods#11402 with the resource bundle for the privacy manifest.
  # 1.13.0: visionOS is recognized as a platform.
  s.cocoapods_version = '>= 1.13.0'

  s.ios.deployment_target = '12.0'
  s.tvos.deployment_target = '12.0'
  s.visionos.deployment_target = "1.0"

  s.swift_versions = ['5.0']

  s.subspec 'FlyHUD' do |ss|
    ss.source_files = ['Sources/HUD/**/*.swift']
  end

  s.subspec 'FlyIndicatorHUD' do |ss|
    ss.source_files = ['Sources/IndicatorHUD/**/*.swift']
    ss.dependency 'FlyHUD/FlyHUD'
  end

  s.subspec 'FlyProgressHUD' do |ss|
    ss.source_files = ['Sources/ProgressHUD/**/*.swift']
    ss.dependency 'FlyHUD/FlyHUD'
  end

  s.resource_bundles = {'FlyHUD' => ['Sources/HUD/PrivacyInfo.xcprivacy']}
end
