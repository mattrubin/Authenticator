platform :ios, '8.0'

pod 'SVProgressHUD', '~> 1.0'

post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods/Pods-acknowledgements.plist', 'Authenticator/Resources/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end
