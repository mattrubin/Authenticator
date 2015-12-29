//
//  TableViewModel.swift
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

import Foundation

protocol TableViewModelFamily {
    typealias HeaderModel
    typealias RowModel
    typealias Action
}

struct TableViewModel<T: TableViewModelFamily> {
    typealias HeaderModel = T.HeaderModel
    typealias RowModel = T.RowModel
    typealias Action = T.Action

    var title: String
    var leftBarButton: BarButtonViewModel<Action>?
    var rightBarButton: BarButtonViewModel<Action>?
    var sections: [Section<HeaderModel, RowModel>]
    var doneKeyAction: Action
    var errorMessage: String?

    init(title: String,
        leftBarButton: BarButtonViewModel<Action>? = nil,
        rightBarButton: BarButtonViewModel<Action>? = nil,
        sections: [Section<HeaderModel, RowModel>],
        doneKeyAction: Action,
        errorMessage: String? = nil) {
            self.title = title
            self.leftBarButton = leftBarButton
            self.rightBarButton = rightBarButton
            self.sections = sections
            self.doneKeyAction = doneKeyAction
            self.errorMessage = errorMessage
    }
}

extension TableViewModel {
    var numberOfSections: Int {
        return sections.count
    }

    func numberOfRowsInSection(section: Int) -> Int {
        guard sections.indices.contains(section) else {
            return 0
        }
        return sections[section].rows.count
    }

    func modelForRowAtIndexPath(indexPath: NSIndexPath) -> RowModel? {
        guard sections.indices.contains(indexPath.section) else {
            return nil
        }
        let section = sections[indexPath.section]
        guard section.rows.indices.contains(indexPath.row) else {
            return nil
        }
        return section.rows[indexPath.row]
    }

    func modelForHeaderInSection(section: Int) -> HeaderModel? {
        guard sections.indices.contains(section) else {
            return nil
        }
        return sections[section].header
    }
}