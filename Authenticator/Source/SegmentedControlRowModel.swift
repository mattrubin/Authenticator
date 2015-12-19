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
    typealias Value: Equatable
    typealias Action

    var value: Value { get }
    var changeAction: (Value) -> Action { get }
    var segments: [(title: String, value: Value)] { get }
}

enum TokenType {
    case Counter, Timer
}

struct TokenTypeRowModel: SegmentedControlRowModel {
    typealias Value = TokenType
    typealias Action = Form.Action

    init(value: Value, changeAction: (Value) -> Action) {
        self.value = value
        self.changeAction = changeAction
    }

    let value: Value
    let changeAction: (Value) -> Action
    let segments = [
        (title: "Time Based", value: Value.Timer),
        (title: "Counter Based", value: Value.Counter),
    ]
}

struct DigitCountRowModel: SegmentedControlRowModel {
    typealias Value = Int
    typealias Action = Form.Action

    init(value: Value, changeAction: (Value) -> Action) {
        self.value = value
        self.changeAction = changeAction
    }

    let value: Value
    let changeAction: (Value) -> Action
    let segments = [
        (title: "6 Digits", value: 6),
        (title: "7 Digits", value: 7),
        (title: "8 Digits", value: 8),
    ]
}

struct AlgorithmRowModel: SegmentedControlRowModel {
    typealias Value = Generator.Algorithm
    typealias Action = Form.Action

    init(value: Value, changeAction: (Value) -> Action) {
        self.value = value
        self.changeAction = changeAction
    }

    let value: Value
    let changeAction: (Value) -> Action
    let segments = [
        (title: "SHA-1", value: Value.SHA1),
        (title: "SHA-256", value: Value.SHA256),
        (title: "SHA-512", value: Value.SHA512),
    ]
}
