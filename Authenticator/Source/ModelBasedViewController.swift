//
//  ModelBasedViewController.swift
//  Authenticator
//
//  Created by Beau Collins on 11/10/17.
//  Copyright © 2017 Matt Rubin. All rights reserved.
//

import Foundation

protocol ModelBasedViewController {
    associatedtype ViewModel
    associatedtype Action

    init(viewModel: ViewModel, dispatchAction: @escaping (Action) -> Void)
    func updateWithViewModel(_ viewModel: ViewModel)
}
