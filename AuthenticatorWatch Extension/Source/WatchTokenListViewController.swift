//
//  WatchTokenListController.swift
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

import WatchKit
import Foundation

// this is the root view controller
class WatchTokenListViewController: WKInterfaceController {

    enum UserInput {
        case SelectRow(index:Int)
    }
    typealias UserInputHandler = UserInput -> ()

    // singleton
    static var instance: WatchTokenListViewController?

    @IBOutlet weak var tokenListTable: WKInterfaceTable!

    var handleUserInput: UserInputHandler?

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        // assign singleton
        WatchTokenListViewController.instance = self

    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        handleUserInput?(.SelectRow(index:rowIndex))
    }

}

class WatchTokenListRowController: NSObject {
    @IBOutlet weak var issuerLabel: WKInterfaceLabel!
    @IBOutlet weak var nameLabel: WKInterfaceLabel!
}


// MARK: - Presenter

extension WatchTokenListViewController {

    func updateWithViewModel(viewModel: WatchTokenList.ViewModel,
                             dispatchAction: (WatchTokenList.Action) -> ()) {

        // set the dispatchAction here, since we are not instantiated by the
        // root component.
        self.handleUserInput = {
            switch $0 {
            case .SelectRow(let index):
                let action = viewModel.selectRowAction(index:index)
                dispatchAction(action)
            }
        }

        // this instantiates the number of WatchTokenListRowController needed
        // in the loop below
        tokenListTable.setNumberOfRows(viewModel.rowModels.count, withRowType: "TokenCell")

        for (index, rowModel) in viewModel.rowModels.enumerate() {
            let maybeRowController = tokenListTable.rowControllerAtIndex(index)
            guard let rowController = maybeRowController as? WatchTokenListRowController else {
                print("unexpected row controller type")
                return
            }
            rowController.issuerLabel.setText(rowModel.issuer)
            rowController.nameLabel.setText(rowModel.name)
        }

    }

}
