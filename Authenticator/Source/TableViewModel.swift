//
//  TableViewModel.swift
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

import Foundation

protocol TableViewModelRepresentable {
    associatedtype HeaderModel
    associatedtype RowModel
    associatedtype Action
}

struct TableViewModel<Models: TableViewModelRepresentable> {
    var title: String
    var leftBarButton: BarButtonViewModel<Models.Action>?
    var rightBarButton: BarButtonViewModel<Models.Action>?
    var sections: [Section<Models.HeaderModel, Models.RowModel>]
    var doneKeyAction: Models.Action

    init(title: String,
         leftBarButton: BarButtonViewModel<Models.Action>? = nil,
         rightBarButton: BarButtonViewModel<Models.Action>? = nil,
         sections: [Section<Models.HeaderModel, Models.RowModel>],
         doneKeyAction: Models.Action) {
        self.title = title
        self.leftBarButton = leftBarButton
        self.rightBarButton = rightBarButton
        self.sections = sections
        self.doneKeyAction = doneKeyAction
    }
}

extension TableViewModel {
    var numberOfSections: Int {
        return sections.count
    }

    func numberOfRowsInSection(_ section: Int) -> Int {
        guard sections.indices.contains(section) else {
            return 0
        }
        return sections[section].rows.count
    }

    func modelForRowAtIndexPath(_ indexPath: IndexPath) -> Models.RowModel? {
        guard sections.indices.contains(indexPath.section) else {
            return nil
        }
        let section = sections[indexPath.section]
        guard section.rows.indices.contains(indexPath.row) else {
            return nil
        }
        return section.rows[indexPath.row]
    }

    func modelForHeaderInSection(_ section: Int) -> Models.HeaderModel? {
        guard sections.indices.contains(section) else {
            return nil
        }
        return sections[section].header
    }
}
