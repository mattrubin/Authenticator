//
//  TokenListTests.swift
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

import XCTest
@testable import OneTimePassword
@testable import Authenticator

class TokenListTests: XCTestCase {
    func testFilterByIssuerAndName() {
        var tokenList = mockList([
            ("Google", "example@google.com"),
            ("Github", "username"),
            ("Service", "goo"),
        ])
        let effect = tokenList.update(.Filter("goo"))

        let viewModel = tokenList.viewModel
        let filteredIssuers = viewModel.rowModels.map { $0.issuer }

        XCTAssertNil(effect)
        XCTAssertTrue(viewModel.isFiltering)
        XCTAssertEqual(viewModel.totalTokens, 3)
        XCTAssertEqual(filteredIssuers, ["Google", "Service"])
    }

    func testIsFilteringWhenAllTokensMatchFilter() {
        var tokenList = mockList([
            ("Service", "example@google.com"),
            ("Service", "username"),
        ])
        let effect = tokenList.update(.Filter("Service"))
        let viewModel = tokenList.viewModel

        XCTAssertNil(effect)
        XCTAssertTrue(viewModel.isFiltering)
    }
}

func mockList(list: [(String, String)]) -> TokenList {
    let tokens = list.map { (issuer, name) -> PersistentToken in
        mockPersistentToken(name: name, issuer: issuer)
    }
    return TokenList(persistentTokens: tokens, displayTime: DisplayTime(date: NSDate()))
}

func mockToken(name name: String, issuer: String, secret: String = "mocksecret") -> Token {
    // swiftlint:disable force_unwrapping
    let generator = Generator(factor: .Timer(period: 60),
                              secret: secret.dataUsingEncoding(NSUTF8StringEncoding)!,
                              algorithm: .SHA256,
                              digits: 6)!
    // swiftlint:enable force_unwrapping
    return Token(name: name, issuer: issuer, generator: generator)
}

func mockPersistentToken(name name: String, issuer: String, secret: String = "mocksecret") -> PersistentToken {
    let token = mockToken(name: name, issuer: issuer, secret: secret)
    return PersistentToken(token: token, identifier: PersistentToken.makeUniqueIdentifier())
}
