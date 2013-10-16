platform :ios, '7.0'

pod 'SVProgressHUD', '0.9'
pod 'google-toolbox-for-authenticator', :podspec => 'google-toolbox-for-authenticator.podspec'

post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Pods-Acknowledgements.plist', 'Authenticator/Resources/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end
