# Authenticator
### Two-Factor Authentication Client for iOS.


This app generates and displays one-time passwords for logging into systems which use two-factor authentication, or any other system which supports [counter-based](https://tools.ietf.org/html/rfc4226) or [time-based](https://tools.ietf.org/html/rfc6238) OTPs. The goal of this project is to create a free, simple, open-source alternative to Google Authenticator. This project was based on the neglected open-source [Google Authenticator](https://code.google.com/p/google-authenticator/) client for iOS, and has been rewritten to create a clean code-base using modern APIs.

OTP secret keys can be entered into the app manually, via an iOS cross-app URL scheme, or by scanning a QR code with the in-app QR reader. The [format for key URIs](https://code.google.com/p/google-authenticator/wiki/KeyUriFormat) is supported by many OTP apps and is often presented to the user as a QR code when they are activating two-factor authentication for an online account.


## License

This project is made available under the terms of the [MIT License](http://opensource.org/licenses/MIT). The original project on which it is based is licensed under the [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0). Files present in the earlier project still bear the original license in their header comments. Files which are new or have been entirely rewritten contain the new license in their headers.