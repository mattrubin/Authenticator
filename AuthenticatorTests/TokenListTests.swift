//
//  TokenListTests.swift
//  Authenticator
//
//  Copyright (c) 2016-2026 Authenticator authors
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

import XCTest
@testable import OneTimePassword
@testable import Authenticator

class TokenListTests: XCTestCase {
    private let defaultDigitGroupSize = 2
    let displayTime = DisplayTime(date: Date())

    func testFilterByIssuerAndName() {
        var tokenList = TokenList()
        let persistentTokens = mockPersistentTokens([
            ("Google", "example@google.com"),
            ("Github", "username"),
            ("Service", "goo"),
        ])
        let effect = tokenList.update(with: .filter("goo"))

        let (viewModel, _) = tokenList.viewModel(with: persistentTokens,
                                                 at: displayTime,
                                                 digitGroupSize: defaultDigitGroupSize)
        let filteredIssuers = viewModel.rowModels.map { $0.issuer }

        XCTAssertNil(effect)
        XCTAssertTrue(viewModel.isFiltering)
        XCTAssertEqual(viewModel.totalTokens, 3)
        XCTAssertEqual(filteredIssuers, ["Google", "Service"])
    }

    func testIsFilteringWhenAllTokensMatchFilter() {
        var tokenList = TokenList()

        let persistentTokens = mockPersistentTokens([
            ("Service", "example@google.com"),
            ("Service", "username"),
        ])
        let effect = tokenList.update(with: .filter("Service"))
        let (viewModel, _) = tokenList.viewModel(with: persistentTokens,
                                                 at: displayTime,
                                                 digitGroupSize: defaultDigitGroupSize)

        XCTAssertNil(effect)
        XCTAssertTrue(viewModel.isFiltering)
    }

    func testActionShowBackupInfo() {
        var tokenList = TokenList()
        let action: TokenList.Action = .showBackupInfo
        let effect = tokenList.update(with: action)
        // TODO: check that the token list hasn't changed

        switch effect {
        case .some(.showBackupInfo):
            break
        default:
            XCTFail("Expected .showBackupInfo, got \(String(describing: effect))")
            return
        }
    }

    func testActionShowInfo() {
        var tokenList = TokenList()
        let action: TokenList.Action = .showInfo
        let effect = tokenList.update(with: action)
        // TODO: check that the token list hasn't changed

        switch effect {
        case .some(.showInfo):
            break
        default:
            XCTFail("Expected .showLicenseInfo, got \(String(describing: effect))")
            return
        }
    }

    func testActionEquality() {
        let persistentTokenA = mockPersistentToken(name: "Name", issuer: "Issuer")
        let persistentTokenB = mockPersistentToken(name: "Something", issuer: "Else")

        // BeginAddToken
        XCTAssertEqual(TokenList.Action.beginAddToken, .beginAddToken)
        XCTAssertNotEqual(TokenList.Action.beginAddToken, .clearFilter)

        // EditPersistentToken(PersistentToken)
        XCTAssertEqual(TokenList.Action.editPersistentToken(persistentTokenA), .editPersistentToken(persistentTokenA))
        XCTAssertNotEqual(TokenList.Action.editPersistentToken(persistentTokenA), .editPersistentToken(persistentTokenB))
        XCTAssertNotEqual(TokenList.Action.editPersistentToken(persistentTokenA), .beginAddToken)

        // UpdatePersistentToken(PersistentToken)
        XCTAssertEqual(TokenList.Action.updatePersistentToken(persistentTokenA), .updatePersistentToken(persistentTokenA))
        XCTAssertNotEqual(TokenList.Action.updatePersistentToken(persistentTokenA), .updatePersistentToken(persistentTokenB))
        XCTAssertNotEqual(TokenList.Action.updatePersistentToken(persistentTokenA), .beginAddToken)

        // MoveToken(fromIndex: Int, toIndex: Int)
        XCTAssertEqual(TokenList.Action.moveToken(fromIndex: 0, toIndex: 1), .moveToken(fromIndex: 0, toIndex: 1))
        XCTAssertNotEqual(TokenList.Action.moveToken(fromIndex: 0, toIndex: 1), .moveToken(fromIndex: 0, toIndex: 2))
        XCTAssertNotEqual(TokenList.Action.moveToken(fromIndex: 2, toIndex: 1), .moveToken(fromIndex: 0, toIndex: 1))
        XCTAssertNotEqual(TokenList.Action.moveToken(fromIndex: 0, toIndex: 1), .beginAddToken)

        // DeletePersistentToken(PersistentToken)
        XCTAssertEqual(TokenList.Action.deletePersistentToken(persistentTokenA), .deletePersistentToken(persistentTokenA))
        XCTAssertNotEqual(TokenList.Action.deletePersistentToken(persistentTokenA), .deletePersistentToken(persistentTokenB))
        XCTAssertNotEqual(TokenList.Action.deletePersistentToken(persistentTokenA), .beginAddToken)

        // CopyPassword(String)
        XCTAssertEqual(TokenList.Action.copyPassword("123"), .copyPassword("123"))
        XCTAssertNotEqual(TokenList.Action.copyPassword("123"), .copyPassword("456"))
        XCTAssertNotEqual(TokenList.Action.copyPassword("123"), .beginAddToken)

        // Filter(String)
        XCTAssertEqual(TokenList.Action.filter("ABC"), .filter("ABC"))
        XCTAssertNotEqual(TokenList.Action.filter("ABC"), .filter("XYZ"))
        XCTAssertNotEqual(TokenList.Action.filter("ABC"), .beginAddToken)

        // ClearFilter
        XCTAssertEqual(TokenList.Action.clearFilter, .clearFilter)
        XCTAssertNotEqual(TokenList.Action.clearFilter, .showBackupInfo)

        // ShowBackupInfo
        XCTAssertEqual(TokenList.Action.showBackupInfo, .showBackupInfo)
        XCTAssertNotEqual(TokenList.Action.showBackupInfo, .beginAddToken)

        // ShowLicenseInfo
        XCTAssertEqual(TokenList.Action.showInfo, .showInfo)
        XCTAssertNotEqual(TokenList.Action.showInfo, .beginAddToken)
    }
}

func mockPersistentTokens(_ list: [(String, String)]) -> [PersistentToken] {
    return list.map { (issuer, name) -> PersistentToken in
        mockPersistentToken(name: name, issuer: issuer)
    }
}

func mockToken(name: String, issuer: String, secret: String = "mocksecret") -> Token {
    // swiftlint:disable force_unwrapping
    // swiftlint:disable:next force_try
    let generator = try! Generator(factor: .timer(period: 60),
                                   secret: secret.data(using: String.Encoding.utf8)!,
                                   algorithm: .sha256,
                                   digits: 6)
    // swiftlint:enable force_unwrapping
    return Token(name: name, issuer: issuer, generator: generator)
}

func mockPersistentToken(name: String, issuer: String, secret: String = "mocksecret") -> PersistentToken {
    let token = mockToken(name: name, issuer: issuer, secret: secret)
    return PersistentToken(token: token, identifier: PersistentToken.makeUniqueIdentifier())
}
