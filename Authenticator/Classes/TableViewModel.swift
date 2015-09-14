//
//  TableViewModel.swift
//  Authenticator
//
//  Created by Matt Rubin on 8/29/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

import UIKit

@objc
protocol TableViewModel {
    var numberOfSections: Int { get }
    func numberOfRowsInSection(section: Int) -> Int
    func cellForRowAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell?
    func viewForHeaderInSection(section:Int) -> UIView?
}

class BasicTableViewModel: NSObject, TableViewModel {
    var cells: [[UITableViewCell]] = []

    init(cells: [[UITableViewCell]]) {
        self.cells = cells
    }

    var numberOfSections: Int {
        return cells.count
    }

    func numberOfRowsInSection(section: Int) -> Int {
        if section < cells.startIndex { return 0 }
        if section >= cells.endIndex { return 0 }
        return cells[section].count
    }

    func cellForRowAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell? {
        if indexPath.section < cells.startIndex { return nil }
        if indexPath.section >= cells.endIndex { return nil }
        let sectionCells = cells[indexPath.section]
        if indexPath.row < sectionCells.startIndex { return nil }
        if indexPath.row >= sectionCells.endIndex { return nil }
        return sectionCells[indexPath.row]
    }

    func viewForHeaderInSection(section: Int) -> UIView? {
        return nil
    }
}
