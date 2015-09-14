//
//  Section.swift
//  Authenticator
//
//  Created by Matt Rubin on 9/14/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

import UIKit

struct Section {
    typealias Row = UITableViewCell
    let rows: [Row]
}

extension Section: ArrayLiteralConvertible {
    init(arrayLiteral elements: Row...) {
        rows = elements
    }
}
