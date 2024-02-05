source 'https://cdn.cocoapods.org/'

install! 'cocoapods',
  :disable_input_output_paths => true,
  :generate_multiple_pod_projects => true,
  :share_schemes_for_development_pods => true

#use_frameworks!
use_frameworks! :linkage => :static

target 'Example iOS' do
  platform :ios, '11.0'

  pod 'LPHUD', :path => './'#, :subspecs => ['HUD']

  target 'Example Tests' do
    inherit! :search_paths
  end
end

target 'Example tvOS' do
  platform :tvos, '11.0'

  pod 'LPHUD', :path => './'#, :subspecs => ['HUD']
end
