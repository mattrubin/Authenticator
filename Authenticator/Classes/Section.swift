//
//  Section.swift
//  Authenticator
//
//  Created by Matt Rubin on 9/14/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

import UIKit

struct Section {
    typealias Header = UIView
    typealias Row = UITableViewCell

    let header: Header?
    let rows: [Row]

    init(header: Header? = nil, rows: [Row] = []) {
        self.header = header
        self.rows = rows
    }
}

extension Section: ArrayLiteralConvertible {
    init(arrayLiteral elements: Row...) {
        self.init(rows: elements)
    }
}
