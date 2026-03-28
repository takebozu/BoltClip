platform :osx, '10.15'
use_frameworks!

target 'Clipy' do

  # Application
  pod 'LoginServiceKit', :git => 'https://github.com/Clipy/LoginServiceKit.git'
  pod 'LetsMove'
  # Utility
  pod 'SwiftLint'
  pod 'SwiftGen'

  target 'ClipyTests' do
    inherit! :search_paths
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Ensure all pods use at least macOS 10.15
      if Gem::Version.new(config.build_settings['MACOSX_DEPLOYMENT_TARGET'].to_s) < Gem::Version.new('10.15')
        config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.15'
      end
    end
  end
end