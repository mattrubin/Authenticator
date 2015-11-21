//
//  TokenRowModel.swift
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

struct TokenRowModel: Equatable {
    enum Action: Equatable {
        case UpdateKeychainItem(Token.KeychainItem)
        case EditKeychainItem(Token.KeychainItem)
        case CopyPassword(String)
    }

    let name, issuer, password: String
    let showsButton: Bool
    let buttonAction: Action?
    let selectAction: Action?
    let editAction: Action?

    init(keychainItem: Token.KeychainItem) {
        name = keychainItem.token.name
        issuer = keychainItem.token.issuer
        password = keychainItem.token.currentPassword ?? ""
        if case .Counter = keychainItem.token.generator.factor {
            showsButton = true
        } else {
            showsButton = false
        }
        buttonAction = .UpdateKeychainItem(keychainItem)
        selectAction = .CopyPassword(password)
        editAction = .EditKeychainItem(keychainItem)
    }
}

func == (lhs: TokenRowModel, rhs: TokenRowModel) -> Bool {
    return (lhs.name == rhs.name)
        && (lhs.issuer == rhs.issuer)
        && (lhs.password == rhs.password)
        && (lhs.showsButton == rhs.showsButton)
        && (lhs.buttonAction == rhs.buttonAction)
        && (lhs.selectAction == rhs.selectAction)
        && (lhs.editAction == rhs.editAction)
}

func == (lhs: TokenRowModel.Action, rhs: TokenRowModel.Action) -> Bool {
    switch (lhs, rhs) {
    case let (.UpdateKeychainItem(l), .UpdateKeychainItem(r)):
        return l == r
    case let (.EditKeychainItem(l), .EditKeychainItem(r)):
        return l == r
    case let (.CopyPassword(l), .CopyPassword(r)):
        return l == r
    default:
        return false
    }
}

extension Token.KeychainItem: Equatable {}
public func == (lhs: Token.KeychainItem, rhs: Token.KeychainItem) -> Bool {
    return lhs.persistentRef.isEqualToData(rhs.persistentRef)
        && (lhs.token == rhs.token)
}
