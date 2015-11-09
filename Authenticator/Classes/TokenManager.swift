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

class TokenManager: OTPTokenManager {
    func addToken(token: Token) -> Bool {
        return super.addToken(OTPToken(token: token))
    }

    func tokenAtIndex(index: Int) -> Token {
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        let otpToken = super.tokenAtIndexPath(indexPath)
        return otpToken.token
    }

    func moveTokenFromIndex(origin: Int, toIndex destination: Int) -> Bool {
        let fromIndexPath = NSIndexPath(forRow: origin, inSection: 0)
        let toIndexPath = NSIndexPath(forRow: destination, inSection: 0)
        return super.moveTokenFromIndexPath(fromIndexPath, toIndexPath: toIndexPath)
    }

    func removeTokenAtIndex(index: Int) -> Bool {
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        return super.removeTokenAtIndexPath(indexPath)
    }
}
