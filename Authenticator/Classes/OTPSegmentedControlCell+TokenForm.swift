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

@objc
enum OTPTokenTypeOption: Int {
    case Timer
    case Counter
}

@objc
enum OTPTokenAlgorithmOption: Int {
    case SHA1
    case SHA256
    case SHA512
}

struct TokenTypeRowModel: SegmentedControlRowModel {
    let segments = [
        (title: "Time Based", value: OTPTokenTypeOption.Timer.rawValue),
        (title: "Counter Based", value: OTPTokenTypeOption.Counter.rawValue),
    ]
    let initialValue = OTPTokenTypeOption.Timer.rawValue
}

struct DigitCountRowModel: SegmentedControlRowModel {
    let segments = [
        (title: "6 Digits", value: 6),
        (title: "7 Digits", value: 7),
        (title: "8 Digits", value: 8),
    ]
    let initialValue = 6
}

struct AlgorithmRowModel: SegmentedControlRowModel {
    let segments = [
        (title: "SHA-1", value: OTPTokenAlgorithmOption.SHA1.rawValue),
        (title: "SHA-256", value: OTPTokenAlgorithmOption.SHA256.rawValue),
        (title: "SHA-512", value: OTPTokenAlgorithmOption.SHA512.rawValue),
    ]
    let initialValue = OTPTokenAlgorithmOption.SHA1.rawValue
}

extension OTPSegmentedControlCell {
    static func tokenTypeCell() -> OTPSegmentedControlCell<Int> {
        let cell = OTPSegmentedControlCell<Int>.init()
        cell.updateWithRowModel(TokenTypeRowModel())
        return cell
    }

    static func digitCountCell() -> OTPSegmentedControlCell<Int> {
        let cell = OTPSegmentedControlCell<Int>.init()
        cell.updateWithRowModel(DigitCountRowModel())
        return cell
    }

    static func algorithmCell() -> OTPSegmentedControlCell<Int> {
        let cell = OTPSegmentedControlCell<Int>.init()
        cell.updateWithRowModel(AlgorithmRowModel())
        return cell
    }
}
