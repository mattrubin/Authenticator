//
//  SegmentedControlRowModel.swift
//  Authenticator
//
//  Copyright (c) 2015 Authenticator authors
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

import OneTimePassword

protocol SegmentedControlRowModel {
    typealias Action

    var segments: [(title: String, action: Action)] { get }
    var selectedSegmentIndex: Int? { get }
}

enum TokenType {
    case Counter, Timer
}

struct TokenTypeRowModel<Action>: SegmentedControlRowModel {
    init(value: TokenType, changeAction: (TokenType) -> Action) {
        let options = [
            (title: "Time Based", value: TokenType.Timer),
            (title: "Counter Based", value: TokenType.Counter),
        ]
        segments = options.map({ option in
            return (title: option.title, action: changeAction(option.value))
        })
        selectedSegmentIndex = options.map({ $0.value }).indexOf(value)
    }

    let segments: [(title: String, action: Action)]
    let selectedSegmentIndex: Int?
}

struct DigitCountRowModel<Action>: SegmentedControlRowModel {
    typealias Value = Int

    init(value: Value, changeAction: (Value) -> Action) {
        self.value = value
        self.changeAction = changeAction
    }

    let value: Value
    let changeAction: (Value) -> Action
    let options = [
        (title: "6 Digits", value: 6),
        (title: "7 Digits", value: 7),
        (title: "8 Digits", value: 8),
    ]
    var segments: [(title: String, action: Action)] {
        return options.map({ option in
            return (title: option.title, action: changeAction(option.value))
        })
    }
    var selectedSegmentIndex: Int? {
        return options.map({ $0.value }).indexOf(value)
    }
}

struct AlgorithmRowModel<Action>: SegmentedControlRowModel {
    typealias Value = Generator.Algorithm

    init(value: Value, changeAction: (Value) -> Action) {
        self.value = value
        self.changeAction = changeAction
    }

    let value: Value
    let changeAction: (Value) -> Action
    let options = [
        (title: "SHA-1", value: Value.SHA1),
        (title: "SHA-256", value: Value.SHA256),
        (title: "SHA-512", value: Value.SHA512),
    ]
    var segments: [(title: String, action: Action)] {
        return options.map({ option in
            return (title: option.title, action: changeAction(option.value))
        })
    }
    var selectedSegmentIndex: Int? {
        return options.map({ $0.value }).indexOf(value)
    }
}
