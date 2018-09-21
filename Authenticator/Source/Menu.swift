//
//  Menu.swift
//  Authenticator
//
//  Copyright (c) 2018 Authenticator authors
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

struct Menu {
    let infoList: InfoList
    private(set) var child: Child

    enum Child {
        case none
        case info(Info)
        case displayOptions(DisplayOptions)

        var viewModel: Menu.ViewModel.Child {
            switch self {
            case .none:
                return .none
            case .info(let info):
                return .info(info.viewModel)
            case .displayOptions(let displayOptions):
                return .displayOptions(displayOptions.viewModel)
            }
        }
    }

    init() {
        infoList = InfoList()
        child = .none
    }

    init(info: Info) {
        infoList = InfoList()
        child = .info(info)
    }

    var viewModel: ViewModel {
        return ViewModel(infoList: infoList.viewModel, child: child.viewModel)
    }

    struct ViewModel {
        let infoList: InfoList.ViewModel
        let child: Child

        enum Child {
            case none
            case info(Info.ViewModel)
            case displayOptions(DisplayOptions.ViewModel)
        }
    }

    // MARK: -

    enum Error: Swift.Error {
        case badChildState
    }

    mutating func showInfo(_ info: Info) throws {
        guard case .none = child else {
            throw Error.badChildState
        }
        child = .info(info)
    }

    mutating func dismissInfo() throws {
        guard case .info = child else {
            throw Error.badChildState
        }
        child = .none
    }

    mutating func showDisplayOptions() throws {
        guard case .none = child else {
            throw Error.badChildState
        }
        child = .displayOptions(DisplayOptions())
    }

    mutating func dismissDisplayOptions() throws {
        guard case .displayOptions = child else {
            throw Error.badChildState
        }
        child = .none
    }
}
