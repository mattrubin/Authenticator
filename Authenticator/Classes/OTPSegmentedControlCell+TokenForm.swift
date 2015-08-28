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
enum OTPTokenTypeIndex: Int {
    case Timer
    case Counter
}

@objc
enum OTPTokenDigitsIndex: Int {
    case Six
    case Seven
    case Eight
}

@objc
enum OTPTokenAlgorithmIndex: Int {
    case SHA1
    case SHA256
    case SHA512
}

extension OTPSegmentedControlCell {
    static func tokenTypeCell() -> Self {
        let cell = self.init()
        cell.segmentedControl.insertSegmentWithTitle("Time Based", atIndex: OTPTokenTypeIndex.Timer.rawValue, animated: false)
        cell.segmentedControl.insertSegmentWithTitle("Counter Based", atIndex: OTPTokenTypeIndex.Counter.rawValue, animated: false)
        cell.segmentedControl.selectedSegmentIndex = OTPTokenTypeIndex.Timer.rawValue;
        return cell
    }

    static func digitCountCell() -> Self {
        let cell = self.init()
        cell.segmentedControl.insertSegmentWithTitle("6 Digits", atIndex: OTPTokenDigitsIndex.Six.rawValue, animated: false)
        cell.segmentedControl.insertSegmentWithTitle("7 Digits", atIndex: OTPTokenDigitsIndex.Seven.rawValue, animated: false)
        cell.segmentedControl.insertSegmentWithTitle("8 Digits", atIndex: OTPTokenDigitsIndex.Eight.rawValue, animated: false)
        cell.segmentedControl.selectedSegmentIndex = OTPTokenDigitsIndex.Six.rawValue;
        return cell
    }

    static func algorithmCell() -> Self {
        let cell = self.init()
        cell.segmentedControl.insertSegmentWithTitle("SHA-1", atIndex: OTPTokenAlgorithmIndex.SHA1.rawValue, animated: false)
        cell.segmentedControl.insertSegmentWithTitle("SHA-256", atIndex: OTPTokenAlgorithmIndex.SHA256.rawValue, animated: false)
        cell.segmentedControl.insertSegmentWithTitle("SHA-512", atIndex: OTPTokenAlgorithmIndex.SHA512.rawValue, animated: false)
        cell.segmentedControl.selectedSegmentIndex = OTPTokenAlgorithmIndex.SHA1.rawValue;
        return cell
    }
}
