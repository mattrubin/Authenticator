//
//  PasswordPickerController.swift
//  AuthenticatorTokenProvider
//
//  Created by Beau Collins on 11/10/17.
//  Copyright © 2017 Matt Rubin. All rights reserved.
//

import UIKit

class PasswordPickerViewController: UITableViewController {

    fileprivate let dispatchAction: (Picker.Action) -> Void
    fileprivate var viewModel: Picker.ViewModel
    fileprivate var ignoreTableViewUpdates = false

    fileprivate var searchBar = SearchField(
        frame: CGRect(
            origin: .zero,
            size: CGSize(width: 0, height: 44)
        )
    )

    required init(viewModel: Picker.ViewModel, dispatchAction: @escaping (Picker.Action) -> Void) {
        self.viewModel = viewModel
        self.dispatchAction = dispatchAction
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateWithViewModel(_ viewModel: Picker.ViewModel) {
        self.viewModel = viewModel
        tableView.reloadData()
        updatePeripheralViews()
    }

    func updatePeripheralViews() {
        self.searchBar.updateWithViewModel(viewModel.tokenList)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Authenticator"
        self.view.backgroundColor = UIColor.otpBackgroundColor

        // Configure table view
        self.tableView.separatorStyle = .none
        self.tableView.indicatorStyle = .white
        self.tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        self.tableView.allowsSelectionDuringEditing = true

        self.navigationItem.titleView = searchBar
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                 target: self,
                                                                 action: #selector(cancelPicker))

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updatePeripheralViews()

        self.searchBar.textField.addTarget(self, action: #selector(filterTokens), for: .editingChanged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func filterTokens() {
        guard let filter = searchBar.text else {
            return dispatchAction(.tokenListAction(action: .clearFilter))
        }
        dispatchAction(.tokenListAction(action: .filter(filter)))
    }

    func cancelPicker() {
        dispatchAction(.cancel)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.tokenList.rowModels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithClass(TokenRowCell.self)
        updateCell(cell, forRowAtIndexPath: indexPath)
        return cell
    }

    fileprivate func updateCell(_ cell: TokenRowCell, forRowAtIndexPath indexPath: IndexPath) {
        let rowModel = viewModel.tokenList.rowModels[indexPath.row]
        cell.updateWithRowModel(rowModel)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowModel = viewModel.tokenList.rowModels[indexPath.row]
        dispatchAction(.tokenListAction(action: rowModel.selectAction))
    }

}

extension PasswordPickerViewController: ModelBasedViewController {
}
