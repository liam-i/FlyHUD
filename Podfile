source 'https://cdn.cocoapods.org/'

install! 'cocoapods',
  :disable_input_output_paths => true,
  :generate_multiple_pod_projects => true

#use_frameworks!
use_frameworks! :linkage => :static

target 'HUD_Example' do
  platform :ios, '11.0'

  pod 'LPHUD', :path => './'#, :subspecs => ['HUDIndicator']

  target 'HUD_Tests' do
    inherit! :search_paths
  end
end

target 'HUD_ExampleTV' do
  platform :tvos, '11.0'

  pod 'LPHUD', :path => './'#, :subspecs => ['HUDIndicator']
end
