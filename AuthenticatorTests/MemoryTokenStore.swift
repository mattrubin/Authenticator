//
//  MemoryTokenStore.swift
//  Authenticator
//
//  Created by Beau Collins on 10/14/16.
//  Copyright © 2016 Matt Rubin. All rights reserved.
//

import Foundation
import OneTimePassword
@testable import Authenticator

class MemoryTokenStore : TokenStore {

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
    enum TokenError : ErrorType {
        case IdentifierMissing
    }

    init( token: Token ) throws {
        self.token = token
        let url = try token.toURL()

        guard let data = (url.absoluteString?.dataUsingEncoding(NSUTF8StringEncoding)) else {
            throw TokenError.IdentifierMissing
        }

        identifier = data

    }
}
