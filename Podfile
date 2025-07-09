source 'https://cdn.cocoapods.org/'

install! 'cocoapods',
  :disable_input_output_paths => true,
  :generate_multiple_pod_projects => true,
  :share_schemes_for_development_pods => true

#use_frameworks!
#use_frameworks! :linkage => :static
use_frameworks! :linkage => :dynamic

workspace 'FlyHUD.xcworkspace'

target 'Example iOS' do
  platform :ios, '13.0'

  pod 'FlyHUD', :path => './'#, :subspecs => ['FlyHUD']

  target 'Example Tests' do
    inherit! :search_paths
  end
end

target 'Example tvOS' do
  platform :tvos, '13.0'

  pod 'FlyHUD', :path => './'#, :subspecs => ['FlyHUD']
end
