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
    var segments: [(title: String, value: Value)] { get }
    var value: Value { get }
    var changeAction: (Value) -> Form.Action { get }
}

enum TokenType {
    case Counter, Timer
}

struct TokenTypeRowModel: SegmentedControlRowModel {
    typealias Value = TokenType
    let segments = [
        (title: "Time Based", value: Value.Timer),
        (title: "Counter Based", value: Value.Counter),
    ]
    let value: Value
    let changeAction: (Value) -> Form.Action

    init(value: Value, changeAction: (Value) -> Form.Action) {
        self.value = value
        self.changeAction = changeAction
    }
}

struct DigitCountRowModel: SegmentedControlRowModel {
    typealias Value = Int
    let segments = [
        (title: "6 Digits", value: 6),
        (title: "7 Digits", value: 7),
        (title: "8 Digits", value: 8),
    ]
    let value: Value
    let changeAction: (Value) -> Form.Action

    init(value: Value, changeAction: (Value) -> Form.Action) {
        self.value = value
        self.changeAction = changeAction
    }
}

struct AlgorithmRowModel: SegmentedControlRowModel {
    typealias Value = Generator.Algorithm
    let segments = [
        (title: "SHA-1", value: Value.SHA1),
        (title: "SHA-256", value: Value.SHA256),
        (title: "SHA-512", value: Value.SHA512),
    ]
    let value: Value
    let changeAction: (Value) -> Form.Action

    init(value: Value, changeAction: (Value) -> Form.Action) {
        self.value = value
        self.changeAction = changeAction
    }
}
