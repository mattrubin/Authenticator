//
//  DisplayTime.swift
//  Authenticator
//
//  Created by Matt Rubin on 4/6/16.
//  Copyright © 2016 Matt Rubin. All rights reserved.
//

import Foundation

/// A simple value representing a moment in time, stored as the number of seconds since the epoch.
struct DisplayTime: Equatable {
    let timeIntervalSince1970: NSTimeInterval

    init(date: NSDate) {
        timeIntervalSince1970 = date.timeIntervalSince1970
    }
}

func == (lhs: DisplayTime, rhs: DisplayTime) -> Bool {
    return lhs.timeIntervalSince1970 == rhs.timeIntervalSince1970
}
