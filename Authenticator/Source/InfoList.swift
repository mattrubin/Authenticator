//
//  InfoList.swift
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

struct InfoList {
    // MARK: View

    struct ViewModel {
        let title: String
        let rowModels: [RowModel]
    }

    struct RowModel {
        let title: String
        let description: String
        let callToAction: String
        let action: Effect
    }

    var viewModel: ViewModel {
        let backupDescription = "For security reasons, tokens will be stored only on this device, and will not be included in iCloud or unencrypted backups."
        let licenseDescription = "Authenticator makes use of several third party libraries."

        return ViewModel(title: "Info", rowModels: [
            RowModel(title: "Backups",
                     description: backupDescription,
                     callToAction: "Learn More →".replacingOccurrences(of: " ", with: "\u{00A0}"),
                     action: .showBackupInfo),
            RowModel(title: "Open Source",
                     description: licenseDescription,
                     callToAction: "View Acknowledgements →".replacingOccurrences(of: " ", with: "\u{00A0}"),
                     action: .showLicenseInfo),
        ])
    }

    // MARK: Update

    enum Effect {
        case showBackupInfo
        case showLicenseInfo
        case done
    }
}
