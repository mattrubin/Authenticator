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
    fileprivate let dispatchAction: (DisplayOptions.Action) -> Void
    fileprivate var viewModel: TableViewModel<DisplayOptions> {
        didSet {
            guard oldValue.sections.count == viewModel.sections.count else {
                // Automatic updates aren't implemented for changing number of sections
                tableView.reloadData()
                return
            }

            let changes = viewModel.sections.indices.flatMap { sectionIndex -> [Change<IndexPath>] in
                let oldSection = oldValue.sections[sectionIndex]
                let newSection = viewModel.sections[sectionIndex]
                let changes = changesFrom(oldSection.rows, to: newSection.rows)
                return changes.map({ change in
                    change.map({ row in
                        IndexPath(row: row, section: sectionIndex)
                    })
                })
            }
            tableView.applyChanges(changes, updateRow: updateRow(at:))
        }
    }

    init(viewModel: TableViewModel<DisplayOptions>, dispatchAction: @escaping (DisplayOptions.Action) -> Void) {
        self.viewModel = viewModel
        self.dispatchAction = dispatchAction
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .otpBackgroundColor
        view.tintColor = .otpForegroundColor
        tableView.separatorStyle = .none

        // Set up top bar
        title = viewModel.title
        updateBarButtonItems()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if CommandLine.isDemo {
            // If this is a demo, don't show the keyboard.
            return
        }

        focusFirstField()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unfocus()
    }

    // MARK: Focus

    @discardableResult
    private func focusFirstField() -> Bool {
        for cell in tableView.visibleCells {
            if let focusCell = cell as? FocusCell {
                return focusCell.focus()
            }
        }
        return false
    }

    fileprivate func nextVisibleFocusCell(after currentIndexPath: IndexPath) -> FocusCell? {
        if let visibleIndexPaths = tableView.indexPathsForVisibleRows {
            for indexPath in visibleIndexPaths {
                if currentIndexPath.compare(indexPath) == .orderedAscending {
                    if let focusCell = tableView.cellForRow(at: indexPath) as? FocusCell {
                        return focusCell
                    }
                }
            }
        }
        return nil
    }

    @discardableResult
    private func unfocus() -> Bool {
        return view.endEditing(false)
    }

    // MARK: - Target Actions

    @objc
    func leftBarButtonAction() {
        if let action = viewModel.leftBarButton?.action {
            dispatchAction(action)
        }
    }

    @objc
    func rightBarButtonAction() {
        if let action = viewModel.rightBarButton?.action {
            dispatchAction(action)
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(inSection: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let rowModel = viewModel.modelForRow(at: indexPath) else {
            return UITableViewCell()
        }
        return cell(for: rowModel, in: tableView)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // An apparent rendering error can occur when the table view is scrolled programmatically, causing a cell
        // scrolled off of the screen to appear with a black background when scrolled back onto the screen. Setting the
        // background color of the cell to the table view's background color, instead of to `.clear`, fixes the issue.
        cell.backgroundColor = .otpBackgroundColor
        cell.selectionStyle = .none

        cell.textLabel?.textColor = .otpForegroundColor
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let rowModel = viewModel.modelForRow(at: indexPath) else {
            return 0
        }
        return heightForRow(with: rowModel)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let headerModel = viewModel.modelForHeader(inSection: section) else {
            return CGFloat.ulpOfOne
        }
        return heightForHeader(with: headerModel)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerModel = viewModel.modelForHeader(inSection: section) else {
            return nil
        }
        return viewForHeader(with: headerModel)
    }
}

// MARK: - View Model Helpers

extension DisplayOptionsViewController {
    // MARK: Bar Button View Model

    private func barButtonItem(for viewModel: BarButtonViewModel<DisplayOptions.Action>, target: AnyObject?, action: Selector) -> UIBarButtonItem {
        func systemItem(for style: BarButtonStyle) -> UIBarButtonSystemItem {
            switch style {
            case .done:
                return .done
            case .cancel:
                return .cancel
            }
        }

        let barButtonItem = UIBarButtonItem(
            barButtonSystemItem: systemItem(for: viewModel.style),
            target: target,
            action: action
        )
        barButtonItem.isEnabled = viewModel.enabled
        return barButtonItem
    }

    func updateBarButtonItems() {
        navigationItem.leftBarButtonItem = viewModel.leftBarButton.map { (viewModel) in
            let action = #selector(DisplayOptionsViewController.leftBarButtonAction)
            return barButtonItem(for: viewModel, target: self, action: action)
        }
        navigationItem.rightBarButtonItem = viewModel.rightBarButton.map { (viewModel) in
            let action = #selector(DisplayOptionsViewController.rightBarButtonAction)
            return barButtonItem(for: viewModel, target: self, action: action)
        }
    }

    // MARK: Row Model

    func cell(for rowModel: DisplayOptions.RowModel, in tableView: UITableView) -> UITableViewCell {
        switch rowModel {
        case let .segmentedControlRow(row):
            let cell = tableView.dequeueReusableCell(withClass: SegmentedControlRowCell<DisplayOptions.Action>.self)
            cell.update(with: row.viewModel)
            cell.dispatchAction = dispatchAction
            return cell
        }
    }

    func updateRow(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            // If the given row is not visible, the table view will have no cell for it, and it
            // doesn't need to be updated.
            return
        }
        guard let rowModel = viewModel.modelForRow(at: indexPath) else {
            // If there is no row model for the given index path, just tell the table view to
            // reload it and hope for the best.
            tableView.reloadRows(at: [indexPath], with: .automatic)
            return
        }

        switch rowModel {
        case let .segmentedControlRow(row):
            if let cell = cell as? SegmentedControlRowCell<DisplayOptions.Action> {
                cell.update(with: row.viewModel)
            } else {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
    }

    func heightForRow(with rowModel: DisplayOptions.RowModel) -> CGFloat {
        switch rowModel {
        case let .segmentedControlRow(row):
            return SegmentedControlRowCell<DisplayOptions.Action>.heightForRow(with: row.viewModel)
        }
    }

    // MARK: Header Model

    func viewForHeader(with headerModel: DisplayOptions.HeaderModel) -> UIView {
        switch headerModel {
        }
    }

    func heightForHeader(with headerModel: DisplayOptions.HeaderModel) -> CGFloat {
        switch headerModel {
        }
    }
}

extension DisplayOptionsViewController {
    func update(with viewModel: TableViewModel<DisplayOptions>) {
        self.viewModel = viewModel
        updateBarButtonItems()
    }
}
