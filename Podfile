platform :ios, '7.0'

pod 'OneTimePassword', '~> 1.0'
pod 'SVProgressHUD', '~> 1.0'
pod 'UIColor+Categories', '~> 0.2'
pod 'MRX', :git => 'https://github.com/mattrubin/MRX.git'

post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Pods-Acknowledgements.plist', 'Authenticator/Resources/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end
