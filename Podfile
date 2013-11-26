platform :ios, '7.0'

pod 'SVProgressHUD', '0.9'
pod 'Base32', '~> 1.0.1'
pod 'MRX', :git => 'https://github.com/mattrubin/MRX.git'

post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Pods-Acknowledgements.plist', 'Authenticator/Resources/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end
