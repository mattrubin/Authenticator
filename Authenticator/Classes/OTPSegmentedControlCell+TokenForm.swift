//
//  OTPSegmentedControlCell+TokenForm.swift
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

import OneTimePasswordLegacy

struct TokenTypeRowModel: SegmentedControlRowModel {
    let segments = [
        (title: "Time Based", value: OTPTokenType.Timer),
        (title: "Counter Based", value: OTPTokenType.Counter),
    ]
    let initialValue: OTPTokenType
    let valueChangedAction: (OTPTokenType) -> ()

    init(initialValue: OTPTokenType, valueChangedAction: (OTPTokenType) -> ()) {
        self.initialValue = initialValue
        self.valueChangedAction = valueChangedAction
    }
}

struct DigitCountRowModel: SegmentedControlRowModel {
    let segments = [
        (title: "6 Digits", value: 6),
        (title: "7 Digits", value: 7),
        (title: "8 Digits", value: 8),
    ]
    let initialValue: Int
    let valueChangedAction: (Int) -> ()

    init(initialValue: Int, valueChangedAction: (Int) -> ()) {
        self.initialValue = initialValue
        self.valueChangedAction = valueChangedAction
    }
}

struct AlgorithmRowModel: SegmentedControlRowModel {
    let segments = [
        (title: "SHA-1", value: OTPAlgorithm.SHA1),
        (title: "SHA-256", value: OTPAlgorithm.SHA256),
        (title: "SHA-512", value: OTPAlgorithm.SHA512),
    ]
    let initialValue: OTPAlgorithm
    let valueChangedAction: (OTPAlgorithm) -> ()

    init(initialValue: OTPAlgorithm, valueChangedAction: (OTPAlgorithm) -> ()) {
        self.initialValue = initialValue
        self.valueChangedAction = valueChangedAction
    }
}
