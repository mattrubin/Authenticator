# Authenticator
### Two-Factor Authentication Client for iOS.


This app generates and displays one time passwords for logging in to systems which use two-factor authentication, or any other system which supports [HOTP](http://tools.ietf.org/html/rfc4226) or [TOTP](http://tools.ietf.org/html/rfc6238). This is a fork of the open-source [Google Authenticator](https://code.google.com/p/google-authenticator/) client for iOS.

## Configuration

It is designed to be configured via a URL handler, as follows:

    otpauth://TYPE/LABEL?PARAMETERS

where `TYPE` is "`hotp`" or "`totp`" and `LABEL` is a human readable label to help distinguish multiple otp generators.

The supported `PARAMETERS` are:

```
  algorithm=(SHA1|SHA256|SHA512|MD5)
    OPTIONAL, defaults to SHA1.

  secret=[websafe Base64 encoded secret key, no padding]
    REQUIRED, 128 bits or more.

  digits=(6|8)
    OPTIONAL, defaults to 6.

  counter=N  (hotp specific)
    REQUIRED

  period=N  (totp specific)
    OPTIONAL, defaults to 30.
```
