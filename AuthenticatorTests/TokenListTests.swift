//
//  TokenListTests.swift
//  Authenticator
//
//  Copyright (c) 2016-2023 Authenticator authors
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
        XCTAssert(TokenList.Action.beginAddToken == .beginAddToken)
        XCTAssert(TokenList.Action.beginAddToken != .clearFilter)

        // EditPersistentToken(PersistentToken)
        XCTAssert(TokenList.Action.editPersistentToken(persistentTokenA) == .editPersistentToken(persistentTokenA))
        XCTAssert(TokenList.Action.editPersistentToken(persistentTokenA) != .editPersistentToken(persistentTokenB))
        XCTAssert(TokenList.Action.editPersistentToken(persistentTokenA) != .beginAddToken)

        // UpdatePersistentToken(PersistentToken)
        XCTAssert(TokenList.Action.updatePersistentToken(persistentTokenA) == .updatePersistentToken(persistentTokenA))
        XCTAssert(TokenList.Action.updatePersistentToken(persistentTokenA) != .updatePersistentToken(persistentTokenB))
        XCTAssert(TokenList.Action.updatePersistentToken(persistentTokenA) != .beginAddToken)

        // MoveToken(fromIndex: Int, toIndex: Int)
        XCTAssert(TokenList.Action.moveToken(fromIndex: 0, toIndex: 1) == .moveToken(fromIndex: 0, toIndex: 1))
        XCTAssert(TokenList.Action.moveToken(fromIndex: 0, toIndex: 1) != .moveToken(fromIndex: 0, toIndex: 2))
        XCTAssert(TokenList.Action.moveToken(fromIndex: 2, toIndex: 1) != .moveToken(fromIndex: 0, toIndex: 1))
        XCTAssert(TokenList.Action.moveToken(fromIndex: 0, toIndex: 1) != .beginAddToken)

        // DeletePersistentToken(PersistentToken)
        XCTAssert(TokenList.Action.deletePersistentToken(persistentTokenA) == .deletePersistentToken(persistentTokenA))
        XCTAssert(TokenList.Action.deletePersistentToken(persistentTokenA) != .deletePersistentToken(persistentTokenB))
        XCTAssert(TokenList.Action.deletePersistentToken(persistentTokenA) != .beginAddToken)

        // CopyPassword(String)
        XCTAssert(TokenList.Action.copyPassword("123") == .copyPassword("123"))
        XCTAssert(TokenList.Action.copyPassword("123") != .copyPassword("456"))
        XCTAssert(TokenList.Action.copyPassword("123") != .beginAddToken)

        // Filter(String)
        XCTAssert(TokenList.Action.filter("ABC") == .filter("ABC"))
        XCTAssert(TokenList.Action.filter("ABC") != .filter("XYZ"))
        XCTAssert(TokenList.Action.filter("ABC") != .beginAddToken)

        // ClearFilter
        XCTAssert(TokenList.Action.clearFilter == .clearFilter)
        XCTAssert(TokenList.Action.clearFilter != .showBackupInfo)

        // ShowBackupInfo
        XCTAssert(TokenList.Action.showBackupInfo == .showBackupInfo)
        XCTAssert(TokenList.Action.showBackupInfo != .beginAddToken)

        // ShowLicenseInfo
        XCTAssert(TokenList.Action.showInfo == .showInfo)
        XCTAssert(TokenList.Action.showInfo != .beginAddToken)
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
