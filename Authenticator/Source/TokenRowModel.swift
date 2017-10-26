//
//  TokenRowModel.swift
//  Authenticator
//
//  Copyright (c) 2015-2016 Authenticator authors
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

struct TokenRowModel: Identifiable {
    typealias Action = TokenList.Action

    let name, issuer, password: String
    let showsButton: Bool
    let canReorder: Bool
    let buttonAction: Action
    let selectAction: Action
    let editAction: Action
    let deleteAction: Action

    fileprivate let identifier: Data

    init(persistentToken: PersistentToken, displayTime: DisplayTime, canReorder reorderable: Bool = true) {
        let rawPassword = (try? persistentToken.token.generator.password(at: displayTime.date)) ?? ""

        name = persistentToken.token.name
        issuer = persistentToken.token.issuer
        password = TokenRowModel.chunkPassword(rawPassword)
        if case .counter = persistentToken.token.generator.factor {
            showsButton = true
        } else {
            showsButton = false
        }
        buttonAction = .updatePersistentToken(persistentToken)
        selectAction = .copyPassword(rawPassword)
        editAction = .editPersistentToken(persistentToken)
        deleteAction = .deletePersistentToken(persistentToken)
        identifier = persistentToken.identifier
        canReorder = reorderable
    }

    func hasSameIdentity(_ other: TokenRowModel) -> Bool {
        return (self.identifier == other.identifier)
    }

    // Group the password into chunks of two digits, separated by spaces.
    // group by 3 if divisible by 3, 2 if divisible by two. Otherwise do not group.
    private static func chunkPassword(_ password: String) -> String {
        var characters = password.characters
        guard let chunkSize = [3,2].first(where: { characters.count % $0 == 0  } ) else {
            return String(characters)
        }
        for i in stride(from: chunkSize, to: characters.count, by: chunkSize).reversed() {
            characters.insert(" ", at: characters.index(characters.startIndex, offsetBy: i))
        }
        return String(characters)
    }
}

extension TokenRowModel: Equatable {}
func == (lhs: TokenRowModel, rhs: TokenRowModel) -> Bool {
    return (lhs.name == rhs.name)
        && (lhs.issuer == rhs.issuer)
        && (lhs.password == rhs.password)
        && (lhs.showsButton == rhs.showsButton)
        && (lhs.buttonAction == rhs.buttonAction)
        && (lhs.selectAction == rhs.selectAction)
        && (lhs.editAction == rhs.editAction)
        && (lhs.deleteAction == rhs.deleteAction)
        && (lhs.identifier == rhs.identifier)
}
