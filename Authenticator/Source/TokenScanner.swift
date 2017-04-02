//
//  TokenScanner.swift
//  Authenticator
//
//  Copyright (c) 2017 Authenticator authors
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

struct TokenScanner: Component {
    private var tokenFound: Bool

    // MARK: Initialization

    init() {
        tokenFound = false
    }

    // MARK: View

    struct ViewModel {
        var isScanning: Bool
    }

    var viewModel: ViewModel {
        return ViewModel(isScanning: !tokenFound)
    }

    // MARK: Update

    enum Action {
        case cancel
        case beginManualTokenEntry
        case scannerDecodedText(String)
        case scannerError(Error)
    }

    enum Effect {
        case cancel
        case beginManualTokenEntry
        case saveNewToken(Token)
        case showErrorMessage(String)
    }

    mutating func update(_ action: Action) -> Effect? {
        switch action {
        case .cancel:
            return .cancel

        case .beginManualTokenEntry:
            return .beginManualTokenEntry

        case .scannerDecodedText(let text):
            // Attempt to create a token from the decoded text
            guard let url = URL(string: text),
                let token = Token(url: url) else {
                    // Show an error message
                    return .showErrorMessage("Invalid Token")
            }
            tokenFound = true
            return .saveNewToken(token)

        case .scannerError(let error):
            print("Error: \(error)")
            return .showErrorMessage("Capture Failed")
        }
    }
}
