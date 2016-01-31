# Changelog

## 1.1.2 - Sep 19, 2014

[NEW] Support for larger screen sizes.

[FIX] Move token type to the advanced options section

[DEV] Replace the token core with the OneTimePassword library


## 1.1.1 - Jun 19, 2014

[NEW] Advanced options: choose the algorithm and digit count in manual entry.


## 1.1 - May 9, 2014

[NEW] Updated visual design.

[NEW] Dedicated editing screen.

[NEW] Default to QR code entry when the camera is available. (Manual token entry is still possible.)

[NEW] Allow the user to specify an issuer string when manually entering a token.

[DEV] Fixed a token generation bug on 64-bit devices introduced by compiling with Xcode 5.1.


## 1.0.3 - Dec 20, 2013

[NEW] Added an "Issuer" field for labeling tokens.

[FIX] Removed support for MD5-based tokens.

[FIX] Fixed a bug where token edits could be reverted if the password refreshed while editing.


## 1.0.2 - Dec 5, 2013

[FIX] Fixed a bug which prevented adding new tokens after a clean install.

[NEW] Tokens which remain in your keychain after the app is uninstalled are now recovered when the app is reinstalled.


## 1.0.1 - Dec 3, 2013

[NEW] Updated app icon with brighter colors and better layout.

[DEV] Refactored OTPRootViewController into OTPTokenManager and OTPTokenListViewController.


## 1.0 - Nov 25, 2013
