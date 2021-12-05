#
# Be sure to run `pod lib lint HUD.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'HUD'
  s.version          = '1.2.1'
  s.summary          = 'An iOS activity indicator view.'
  s.description      = <<-DESC
                    HUD is an iOS drop-in class that displays a translucent HUD
                    with an indicator and/or labels while work is being done in a background thread.
                    The HUD is meant as a replacement for the undocumented, private UIKit UIProgressHUD
                    with some additional features.
                       DESC

  s.homepage         = 'https://github.com/liam-i/HUD'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Liam' => 'liam_i@163.com' }
  s.source           = { :git => 'https://github.com/liam-i/HUD.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.swift_versions = ['5.1', '5.2', '5.3']

  s.source_files = 'Sources/Classes/**/*'
end
