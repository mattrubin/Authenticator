# [Authenticator] Changelog
All notable changes to the project will be documented in this file.

[Authenticator]: https://github.com/mattrubin/Authenticator


## [2.0.3] - 2018-04-23
- Disabled swipe-to-delete on the token list, to prevent tokens from being accidentally deleted. To delete a token, first tap "Edit" and then tap the red delete button.
- Fixed a bug where the app might crash when adding a token from an "otpauth://" URL.


## [2.0.2] - 2017-12-09
- Improved the accessibility of manual token entry when using VoiceOver
- Improved app efficiency, reducing energy usage and processor load by over 95%


## [2.0.1] - 2017-11-07
- Added support for iPhone X
- Fixed a bug where tokens were sometimes copied when trying to scroll the token list
- Fixed button text color and font weight on iOS 11


## [2.0.0] - 2017-06-08
- Rewrote the app in Swift using a new architecture inspired by [React], [Redux], and [Elm].  
- Moved token models, persistence, and password generation to the [OneTimePassword] library.  

[React]: http://facebook.github.io/react/
[Redux]: http://redux.js.org
[Elm]: http://elm-lang.org
[OneTimePassword]: https://github.com/mattrubin/OneTimePassword

#### Search & Filter
Tap the new search field at the top of the token list to filter your tokens by issuer and account name.

#### Easier to Read
An updated font, improved typography, and better spacing make your passwords easier to read.

#### Security & Backup Info
For security reasons, tokens are stored only on one device, and are not included in iCloud or unencrypted backups. More information about security and backups has been added in the app.

#### Also…
- Haptic Feedback
- Improved Error Messages
- Many small improvements to polish and performance…


## [1.1.2.1] - 2014-09-19
### Fixed
- Bumped deployment target to iOS 8 to support XIB-based launch screens.


## [1.1.2] - 2014-09-19

[NEW] Support for larger screen sizes.

[FIX] Move token type to the advanced options section

[DEV] Replace the token core with the OneTimePassword library


## [1.1.1] - 2014-06-19

[NEW] Advanced options: choose the algorithm and digit count in manual entry.


## [1.1] - 2014-05-09

[NEW] Updated visual design.

[NEW] Dedicated editing screen.

[NEW] Default to QR code entry when the camera is available. (Manual token entry is still possible.)

[NEW] Allow the user to specify an issuer string when manually entering a token.

[DEV] Fixed a token generation bug on 64-bit devices introduced by compiling with Xcode 5.1.


## [1.0.3] - 2013-12-20

[NEW] Added an "Issuer" field for labeling tokens.

[FIX] Removed support for MD5-based tokens.

[FIX] Fixed a bug where token edits could be reverted if the password refreshed while editing.


## [1.0.2] - 2013-12-05

[FIX] Fixed a bug which prevented adding new tokens after a clean install.

[NEW] Tokens which remain in your keychain after the app is uninstalled are now recovered when the app is reinstalled.


## [1.0.1] - 2013-12-03

[NEW] Updated app icon with brighter colors and better layout.

[DEV] Refactored OTPRootViewController into OTPTokenManager and OTPTokenListViewController.


## [1.0] - 2013-11-25


[Unreleased]: https://github.com/mattrubin/Authenticator/compare/2.0.3...HEAD
[2.0.3]: https://github.com/mattrubin/Authenticator/compare/2.0.2...2.0.3
[2.0.2]: https://github.com/mattrubin/Authenticator/compare/2.0.1...2.0.2
[2.0.1]: https://github.com/mattrubin/Authenticator/compare/2.0.0...2.0.1
[2.0.0]: https://github.com/mattrubin/Authenticator/compare/1.1.2.1...2.0.0
[1.1.2.1]: https://github.com/mattrubin/Authenticator/compare/1.1.2...1.1.2.1
[1.1.2]: https://github.com/mattrubin/Authenticator/compare/1.1.1...1.1.2
[1.1.1]: https://github.com/mattrubin/Authenticator/compare/1.1...1.1.1
[1.1]: https://github.com/mattrubin/Authenticator/compare/1.0.3...1.1
[1.0.3]: https://github.com/mattrubin/Authenticator/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/mattrubin/Authenticator/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/mattrubin/Authenticator/compare/1.0...1.0.1
[1.0]: https://github.com/mattrubin/Authenticator/compare/64497eb12e4862ad900dc4a014d2cf2232aa3077...1.0
