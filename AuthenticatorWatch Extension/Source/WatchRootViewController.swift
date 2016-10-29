//
//  WatchRootViewController.swift
//  Authenticator
//
//  Copyright (c) 2013-2016 Authenticator authors
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

// this is a placeholder to make the structure of the watch app
// analogous to that of the main iphone app
class WatchRootViewController {

    private var currentViewModel: WatchRoot.ViewModel

    private var showingEntry = false

    private var tokenListViewController: WatchTokenListViewController? {
        return WatchTokenListViewController.instance
    }

    private let dispatchAction: (WatchRoot.Action) -> ()


    init(viewModel: WatchRoot.ViewModel, dispatchAction: (WatchRoot.Action) -> ()) {
        self.currentViewModel = viewModel
        self.dispatchAction = dispatchAction
    }

}



extension WatchRootViewController {
    func updateWithViewModel(viewModel: WatchRoot.ViewModel) {

        tokenListViewController?.updateWithViewModel(
            viewModel.tokenList,
            dispatchAction: compose(WatchRoot.Action.TokenListAction, dispatchAction)
        )

        switch viewModel.modal {
        case .None:
            // this modal hiding is not really happening, because the
            // watchos ui has already changed.
            if showingEntry {
                // it is visible and presenting? dismiss it!
                WatchEntryViewController.instance?.dismissController()
            }
            showingEntry = false
        case .EntryView(let entryViewModel):
            let dispatchEntryAction = compose(WatchRoot.Action.EntryAction, dispatchAction)
            if !showingEntry {
                // it is not presenting, so make it.

                // seems nigh on impossible to get the entryViewModel into the
                // next controller. a  struct is just not going to fit
                // in an AnyObject? every time we use these static singletons
                // for argument passing, a very cute fairy dies... tragic!
                WatchEntryViewController.viewModel = entryViewModel
                WatchEntryViewController.dispatchAction = dispatchEntryAction

                tokenListViewController?.pushControllerWithName("entry", context: nil)
                showingEntry = true
            } else {
                WatchEntryViewController.instance?.updateWithViewModel(
                    entryViewModel,
                    dispatchAction: dispatchEntryAction
                )
            }
        }
    }
}



private func compose<A, B, C>(transform: A -> B, _ handler: B -> C) -> A -> C {
    return { handler(transform($0)) }
}
