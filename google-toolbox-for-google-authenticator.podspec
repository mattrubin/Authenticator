Pod::Spec.new do |s|
  s.name         = "google-toolbox-for-google-authenticator"
  s.version      = "446"
  s.summary      = "The subset of google-toolbox-for-mac required by google-authenticator."
  s.homepage     = "https://code.google.com/p/google-toolbox-for-mac/"
  s.license      = { :type => 'Apache License, Version 2.0', :file => 'COPYING' }
  s.author       = 'Google (https://code.google.com/p/google-toolbox-for-mac/people/list)'
  s.source       = { :svn => "http://google-toolbox-for-mac.googlecode.com/svn/trunk/", :revision => "446" }
  s.platform     = :ios
  s.source_files = 'GTMDefines.h', 'Foundation/GTMStringEncoding.{h,m}', 'Foundation/GTMNSScanner+Unsigned.{h,m}', 'Foundation/GTMNSDictionary+URLArguments.{h,m}', 'Foundation/GTMNSString+URLArguments.{h,m}', 'Foundation/GTMLocalizedString.h', 'DebugUtils/GTMMethodCheck.{h,m}', 'Foundation/GTMGarbageCollection.h', 'Foundation/GTMObjC2Runtime.h'
  s.frameworks   = 'Foundation'
  s.requires_arc = false

  # Workaround for redefinition errors when building for the iOS simulator
  s.prefix_header_contents = <<-EOS
#if TARGET_OS_IPHONE && MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
    #undef MAC_OS_X_VERSION_MIN_REQUIRED
    #define MAC_OS_X_VERSION_MIN_REQUIRED MAC_OS_X_VERSION_10_5
#endif
EOS
end
