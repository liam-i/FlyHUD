Pod::Spec.new do |s|

  s.name         = "LPProgressHUD"
  s.version      = "1.1.0"
  s.summary      = "LPProgressHUD is a Swift version of the HUD that mimics MBProgressHUD."
  s.homepage     = "https://github.com/leo-lp/LPProgressHUD"
  s.license      = "MIT"
  s.author       = { "leo-lp" => "lipengmjy@163.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/leo-lp/LPProgressHUD.git", :tag => "#{s.version}" }
  
  s.ios.deployment_target = '9.0'
  s.swift_versions = ['5.0', '5.1']
  
  s.source_files = "LPProgressHUD/Sources/*.swift"

end
