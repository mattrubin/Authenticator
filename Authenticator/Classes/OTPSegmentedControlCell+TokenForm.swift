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

import OneTimePassword

struct TokenTypeRowViewModel: SegmentedControlRowViewModel {
    let segments = [
        (title: "Time Based", value: Generator.Factor.Timer(period: defaultPeriod)),
        (title: "Counter Based", value: Generator.Factor.Counter(0)),
    ]
    let value: Generator.Factor
    let changeAction: (Generator.Factor) -> ()

    init(value: Generator.Factor, changeAction: (Generator.Factor) -> ()) {
        self.value = value
        self.changeAction = changeAction
    }
}

struct DigitCountRowViewModel: SegmentedControlRowViewModel {
    let segments = [
        (title: "6 Digits", value: 6),
        (title: "7 Digits", value: 7),
        (title: "8 Digits", value: 8),
    ]
    let value: Int
    let changeAction: (Int) -> ()

    init(value: Int, changeAction: (Int) -> ()) {
        self.value = value
        self.changeAction = changeAction
    }
}

struct AlgorithmRowViewModel: SegmentedControlRowViewModel {
    let segments = [
        (title: "SHA-1", value: Generator.Algorithm.SHA1),
        (title: "SHA-256", value: Generator.Algorithm.SHA256),
        (title: "SHA-512", value: Generator.Algorithm.SHA512),
    ]
    let value: Generator.Algorithm
    let changeAction: (Generator.Algorithm) -> ()

    init(value: Generator.Algorithm, changeAction: (Generator.Algorithm) -> ()) {
        self.value = value
        self.changeAction = changeAction
    }
}
