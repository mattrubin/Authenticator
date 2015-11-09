//
//  TokenManager.swift
//  Authenticator
//
//  Copyright (c) 2015 Matt Rubin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import OneTimePassword
import OneTimePasswordLegacy

class TokenManager {
    let core = OTPTokenManager()

    var numberOfTokens: Int {
        return core.mutableTokens.count
    }

    var hasTimeBasedTokens: Bool {
        for object in core.mutableTokens {
            if let otpToken = object as? OTPToken
                where otpToken.type == .Timer {
                    return true
            }
        }
        return false
    }

    func addToken(token: Token) -> Bool {
        let otpToken = OTPToken(token: token)
        if otpToken.saveToKeychain() {
            core.mutableTokens.addObject(otpToken)
            return core.saveTokensToKeychain()
        }
        return false
    }

    func tokenAtIndex(index: Int) -> Token {
        // swiftlint:disable force_cast
        let otpToken = core.mutableTokens[index] as! OTPToken
        // swiftlint:enable force_cast
        return otpToken.token
    }

    func saveToken(token: Token) -> Bool {
        guard let keychainItem = token.identity as? Token.KeychainItem,
            let newKeychainItem = updateKeychainItem(keychainItem, withToken: token) else {
                return false
        }
        // Update the in-memory token, which is still the origin of the table view's data
        if let otpToken = core.tokenWithKeychainItemRef(newKeychainItem.persistentRef) {
            otpToken.updateWithToken(newKeychainItem.token)
        }
        return true
    }

    func moveTokenFromIndex(origin: Int, toIndex destination: Int) -> Bool {
        // swiftlint:disable force_cast
        let otpToken = core.mutableTokens[origin] as! OTPToken
        // swiftlint:enable force_cast
        core.mutableTokens.removeObjectAtIndex(origin)
        core.mutableTokens.insertObject(otpToken, atIndex: destination)
        return core.saveTokensToKeychain()
    }

    func removeTokenAtIndex(index: Int) -> Bool {
        // swiftlint:disable force_cast
        let otpToken = core.mutableTokens[index] as! OTPToken
        // swiftlint:enable force_cast
        if otpToken.removeFromKeychain() {
            core.mutableTokens.removeObjectAtIndex(index)
            return core.saveTokensToKeychain()
        }
        return false
    }
}
