//
//  MemoryTokenStore.swift
//  Authenticator
//
//  Copyright (c) 2016 Authenticator authors
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
@testable import Authenticator

class MemoryTokenStore: TokenStore {

    var persistentTokens: [PersistentToken] = []

    func addToken(token: Token) throws {
        let persistentToken = try PersistentToken(token: token)
        persistentTokens.append(persistentToken)
    }

    func saveToken(token: Token, toPersistentToken: PersistentToken) throws {
        // NOOP already in memory
    }

    func updatePersistentToken(token: PersistentToken) throws {
        // NOOP already in memory
    }

    func deletePersistentToken(token: PersistentToken) throws {
        persistentTokens = persistentTokens.filter { $0 != token }
    }

    func moveTokenFromIndex(index: Int, toIndex newIndex: Int) {
        let token = persistentTokens.removeAtIndex(index)
        persistentTokens.insert(token, atIndex: newIndex)
    }

}

extension PersistentToken {
    enum TokenError: ErrorType {
        case IdentifierMissing
    }

    init(token: Token) throws {
        self.token = token
        let url = try token.toURL()

        guard let data = (url.absoluteString?.dataUsingEncoding(NSUTF8StringEncoding)) else {
            throw TokenError.IdentifierMissing
        }

        identifier = data

    }
}
