Pod::Spec.new do |s|
  s.name             = 'LPHUD'
  s.version          = '1.3.7'
  s.summary          = 'An iOS activity indicator view.'
  s.description      = <<-DESC
                    LPHUD is an iOS drop-in class that displays a translucent HUD
                    with an indicator and/or labels while work is being done in a background thread.
                    The HUD is meant as a replacement for the undocumented, private UIKit UIProgressHUD
                    with some additional features.
                       DESC

  s.homepage         = 'https://github.com/liam-i/HUD'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Liam' => 'liam_i@163.com' }
  s.source           = { :git => 'https://github.com/liam-i/HUD.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = '11.0'
  s.swift_versions = ['5.0']

  s.subspec 'HUD' do |ss|
    ss.source_files = ['Sources/*.swift', 'Sources/Core']
  end

  s.subspec 'IndicatorView' do |ss|
    ss.source_files = ['Sources/ActivityIndicatorView/**/*']
    ss.dependency 'LPHUD/HUD'
  end

  s.subspec 'ProgressView' do |ss|
    ss.source_files = ['Sources/ProgressView/**/*']
    ss.dependency 'LPHUD/HUD'
  end
end
