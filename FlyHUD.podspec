Pod::Spec.new do |s|
  s.name             = 'FlyHUD'
  s.version          = '1.5.7'
  s.summary          = 'A lightweight and easy-to-use HUD for iOS and tvOS apps.'
  s.description      = <<-DESC
                       FlyHUD is a lightweight and easy-to-use HUD designed to display
                        the progress and status of ongoing tasks on iOS and tvOS.
                       DESC

  s.homepage         = 'https://github.com/liam-i/FlyHUD'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Liam' => 'liam_i@163.com' }
  s.source           = { :git => 'https://github.com/liam-i/FlyHUD.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.tvos.deployment_target = '12.0'
  s.swift_versions = ['5.0']

  s.subspec 'FlyHUD' do |ss|
    ss.source_files = ['Sources/HUD/**/*']
  end

  s.subspec 'FlyIndicatorHUD' do |ss|
    ss.source_files = ['Sources/IndicatorHUD/**/*']
    ss.dependency 'FlyHUD/FlyHUD'
  end

  s.subspec 'FlyProgressHUD' do |ss|
    ss.source_files = ['Sources/ProgressHUD/**/*']
    ss.dependency 'FlyHUD/FlyHUD'
  end
end
