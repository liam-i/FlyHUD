source 'https://cdn.cocoapods.org/'

install! 'cocoapods',
  :disable_input_output_paths => true,
  :generate_multiple_pod_projects => true

platform :ios, '11.0'
use_frameworks!

target 'HUD_Example' do
  pod 'LPHUD', :path => './'

  target 'HUD_Tests' do
    inherit! :search_paths
    
  end
end
