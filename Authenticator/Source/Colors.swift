//
//  Colors.swift
//  Authenticator
//
//  Copyright (c) 2014-2015 Authenticator authors
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

import UIKit

extension UIColor {
    private convenience init(red: Int, green: Int, blue: Int) {
        let divisor: CGFloat = 255
        self.init(
            red: CGFloat(red) / divisor,
            green: CGFloat(green) / divisor,
            blue: CGFloat(blue) / divisor,
            alpha: 1
        )
    }

    private struct OTP {
        static let darkColor  = UIColor(red: 35, green: 35, blue: 50)
        static let lightColor = UIColor(red: 250, green: 248, blue: 240)
    }

    class var otpDarkColor: UIColor { return OTP.darkColor }
    class var otpLightColor: UIColor { return OTP.lightColor }

    class var otpBarBackgroundColor: UIColor { return OTP.darkColor }
    class var otpBarForegroundColor: UIColor { return OTP.lightColor }
    class var otpBackgroundColor: UIColor { return OTP.darkColor }
    class var otpForegroundColor: UIColor { return OTP.lightColor }
}
