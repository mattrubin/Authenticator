//
//  Info.swift
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

struct Info {
    fileprivate let title: String
    fileprivate let url: URL

    fileprivate init(title: String, htmlFileName: String) throws {
        self.title = title
        guard let path = Bundle.main.path(forResource: htmlFileName, ofType: "html") else {
            throw Error.missingFile(htmlFileName)
        }
        url = URL(fileURLWithPath: path)
    }

    static func backupInfo() throws -> Info {
        return try Info(title: "Backups", htmlFileName: "BackupInfo")
    }

    static func licenseInfo() throws -> Info {
        return try Info(title: "Acknowledgements", htmlFileName: "Acknowledgements")
    }

    // MARK: View

    struct ViewModel {
        let title: String
        let url: URL
    }

    var viewModel: ViewModel {
        return ViewModel(title: title, url: url)
    }

    // MARK: Update

    enum Effect {
        case done
        case openURL(URL)
    }

    // MARK: Errors

    enum Error: ErrorProtocol {
        case missingFile(String)
    }
}
