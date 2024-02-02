Pod::Spec.new do |s|
  s.name             = 'LPHUD'
  s.version          = '1.5.0'
  s.summary          = 'A lightweight and easy-to-use HUD for iOS and tvOS apps.'
  s.description      = <<-DESC
                        LPHUD is a lightweight and easy-to-use HUD designed to display 
                        the progress and status of ongoing tasks on iOS and tvOS.
                       DESC

  s.homepage         = 'https://github.com/liam-i/HUD'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Liam' => 'liam_i@163.com' }
  s.source           = { :git => 'https://github.com/liam-i/HUD.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = '11.0'
  s.swift_versions = ['5.0']

  s.subspec 'HUD' do |ss|
    ss.source_files = ['Sources/HUD/**/*']
  end

  s.subspec 'HUDIndicator' do |ss|
    ss.source_files = ['Sources/HUDIndicator/**/*']
    ss.dependency 'LPHUD/HUD'
  end

  s.subspec 'HUDProgress' do |ss|
    ss.source_files = ['Sources/HUDProgress/**/*']
    ss.dependency 'LPHUD/HUD'
  end
end
