//
//  WatchEntryViewModel.swift
//  Authenticator
//
//  Copyright (c) 2013-2016 Authenticator authors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import OneTimePassword

struct WatchEntryViewModel {
    typealias Action = WatchTokenList.Action

    let name, issuer: String

    var password: String {
        return _password()
    }
    private let _password:() -> String

    var progress: Double? {
        return _progress()
    }
    private let _progress: () -> Double?

    let isHOTP: Bool

    init(persistentToken: PersistentToken) {
        name = persistentToken.token.name
        issuer = persistentToken.token.issuer
        _password = {
            // Generate the token for the current time
            let now = NSDate().timeIntervalSince1970
            return (try? persistentToken.token.generator.passwordAtTime(now)) ?? ""
        }
        _progress = {
            guard case .Timer(let period) = persistentToken.token.generator.factor else {
                // If there is not a time-based tokens, return nil to hide the progress.
                return nil
            }
            guard period > 0 else {
                // If the period is >= zero, return zero to display the progress
                // but avoid the potential divide-by-zero error below.
                return 0
            }
            // Calculate the percentage progress in the current period.
            return fmod(NSDate().timeIntervalSince1970, period) / period
        }
        // XXX to support HOTP we need to persist tokens back to the phone.
        if case .Counter = persistentToken.token.generator.factor {
            isHOTP = true
        } else {
            isHOTP = false
        }
    }

}
