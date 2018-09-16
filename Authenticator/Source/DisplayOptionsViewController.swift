//
//  DisplayOptionsViewController.swift
//  Authenticator
//
//  Copyright (c) 2018 Authenticator authors
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

import UIKit

final class DisplayOptionsViewController: UITableViewController {
    private var viewModel: DisplayOptions.ViewModel
    private let dispatchAction: (DisplayOptions.Effect) -> Void

    // MARK: Initialization

    init(viewModel: DisplayOptions.ViewModel, dispatchAction: @escaping (DisplayOptions.Effect) -> Void) {
        self.viewModel = viewModel
        self.dispatchAction = dispatchAction
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with viewModel: DisplayOptions.ViewModel) {
        self.viewModel = viewModel
        applyViewModel()
    }

    private func applyViewModel() {
        title = viewModel.title
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = UIColor.otpBackgroundColor
        tableView.separatorStyle = .none
        tableView.indicatorStyle = .white
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44.0

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(done))

        applyViewModel()
    }

    // MARK: Target Actions

    @objc
    func done() {
        dispatchAction(.done)
    }

    /*
    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rowModels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: DisplayOptionsCell.self)
        updateCell(cell, forRowAtIndexPath: indexPath)
        return cell
    }

    fileprivate func updateCell(_ cell: DisplayOptionsCell, forRowAtIndexPath indexPath: IndexPath) {
        let rowModel = viewModel.rowModels[indexPath.row]
        cell.update(with: rowModel)
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowModel = viewModel.rowModels[indexPath.row]
        dispatchAction(rowModel.action)
    }
*/
}

class DisplayOptionsCell: UITableViewCell {
}
