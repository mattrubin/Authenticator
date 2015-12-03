//
//  FormModels.swift
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

enum Form: TableViewModelFamily {
    enum HeaderModel {
        case ButtonHeader(ButtonHeaderViewModel)
    }

    enum RowModel: Identifiable {
        case TextFieldRow(TextFieldRowModel)
        case TokenTypeRow(TokenTypeRowViewModel)
        case DigitCountRow(DigitCountRowViewModel)
        case AlgorithmRow(AlgorithmRowViewModel)

        func hasSameIdentity(other: RowModel) -> Bool {
            // As currently used, form rows don't move around much, so comparing the row
            // type is sufficient here. For more complex changes, row models should be
            // compared for identity.
            switch (self, other) {
            case (.TextFieldRow, .TextFieldRow): return true
            case (.TokenTypeRow, .TokenTypeRow): return true
            case (.DigitCountRow, .DigitCountRow): return true
            case (.AlgorithmRow, .AlgorithmRow): return true
            default: return false
            }
        }
    }

    enum Field: Equatable {
        case Issuer
        case Name
        case Secret
    }
    enum OptionField: Equatable {
        case TokenType
        case DigitCount
        case Algorithm
    }
}
