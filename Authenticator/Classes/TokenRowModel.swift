//
//  TokenRowModel.swift
//  Authenticator
//
//  Created by Matt Rubin on 3/13/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

import OneTimePasswordLegacy

@objc
class TokenRowModel {
    let name: String
    let issuer: String
    let password: String
    let showsButton: Bool

    init(token: OTPToken) {
        self.name = token.name
        self.issuer = token.issuer
        self.password = token.password ?? ""
        self.showsButton = (token.type == .Counter)
    }
}
