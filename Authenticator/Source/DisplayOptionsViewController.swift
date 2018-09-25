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

    init(viewModel: DisplayOptions.ViewModel, dispatchAction: @escaping (DisplayOptions.Action) -> Void) {
        self.viewModel = internalViewModel(for: viewModel)
        self.dispatchAction = dispatchAction
        super.init(nibName: nil, bundle: nil)
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
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44.0

        // Set up top bar
        title = viewModel.title
        updateBarButtonItems()
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
        case let .digitGroupingRow(row):
            let cell = tableView.dequeueReusableCell(withClass: DigitGroupingRowCell<DisplayOptions.Action>.self)
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
        case let .digitGroupingRow(row):
            if let cell = cell as? DigitGroupingRowCell<DisplayOptions.Action> {
                cell.update(with: row.viewModel)
            } else {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
    }
}

extension DisplayOptions: TableViewModelRepresentable {
    enum HeaderModel {}
    enum RowModel: Identifiable {
        case digitGroupingRow(identity: String, viewModel: DigitGroupingRowViewModel<Action>)

        func hasSameIdentity(as other: RowModel) -> Bool {
            switch (self, other) {
            case let (.digitGroupingRow(rowA), .digitGroupingRow(rowB)):
                return rowA.identity == rowB.identity
            }
        }
    }
    typealias Action = Effect
}

private func internalViewModel(for viewModel: DisplayOptions.ViewModel) -> TableViewModel<DisplayOptions> {
    return TableViewModel(
        title: "Display Options",
        rightBarButton: BarButtonViewModel(style: .done, action: .done),
        sections: [[digitGroupRowModel(currentValue: viewModel.digitGroupSize)]],
        doneKeyAction: .done
    )
}

private func digitGroupRowModel(currentValue: Int) -> DisplayOptions.RowModel {
    return .digitGroupingRow(
        identity: "password.digitGroupSize",
        viewModel: DigitGroupingRowViewModel(
            title: "Digit Grouping",
            options: [(title: "•• •• ••", value: 2), (title: "••• •••", value: 3)],
            value: currentValue,
            changeAction: DisplayOptions.Effect.setDigitGroupSize
        )
    )
}

extension DisplayOptionsViewController {
    func update(with viewModel: DisplayOptions.ViewModel) {
        self.viewModel = internalViewModel(for: viewModel)
        updateBarButtonItems()
    }
}

// MARK: Digit Grouping Row

struct DigitGroupingRowViewModel<Action> {
    let title: String
    let segments: [(title: String, action: Action)]
    let selectedSegmentIndex: Int?

    init<V: Equatable>(title: String, options: [(title: String, value: V)], value: V, changeAction: (V) -> Action) {
        self.title = title
        segments = options.map({ option in
            (title: option.title, action: changeAction(option.value))
        })
        selectedSegmentIndex = options.map({ $0.value }).index(of: value)
    }
}

class DigitGroupingRowCell<Action>: UITableViewCell {
    private let titleLabel = UILabel()
    private let segmentedControl = UISegmentedControl()
    private var customConstraints: [NSLayoutConstraint]?

    private var actions: [Action] = []
    var dispatchAction: ((Action) -> Void)?

    // MARK: Initialization

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureCell()
    }

    private func configureCell() {
        backgroundColor = .otpBackgroundColor

        titleLabel.textColor = .otpForegroundColor
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .light)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        let font = UIFont.systemFont(ofSize: 40, weight: .light)
        let fontAttributes = [NSAttributedStringKey.font: font]
        segmentedControl.setTitleTextAttributes(fontAttributes, for: .normal)
        segmentedControl.setContentPositionAdjustment(UIOffset(horizontal: 0, vertical: -3),
                                                      forSegmentType: .any,
                                                      barMetrics: .default)
        let action = #selector(DigitGroupingRowCell.segmentedControlValueChanged)
        segmentedControl.addTarget(self, action: action, for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(segmentedControl)

        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor(white: 0, alpha: 0.25)

        setNeedsUpdateConstraints()
    }

    override func updateConstraints() {
        if customConstraints == nil {
            let newConstraints = [
                titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor, constant: 8),
                titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                segmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
                segmentedControl.heightAnchor.constraint(equalToConstant: 40),
                segmentedControl.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                segmentedControl.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                segmentedControl.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            ]
            contentView.addConstraints(newConstraints)
            customConstraints = newConstraints
        }

        // "Important: Call [super updateConstraints] as the final step in your implementation."
        super.updateConstraints()
    }

    // MARK: Update

    func update(with viewModel: DigitGroupingRowViewModel<Action>) {
        titleLabel.text = viewModel.title

        // Remove any old segments
        segmentedControl.removeAllSegments()
        // Add new segments
        for i in viewModel.segments.indices {
            let segment = viewModel.segments[i]
            segmentedControl.insertSegment(withTitle: segment.title, at: i, animated: false)
        }
        // Store the action associated with each segment
        actions = viewModel.segments.map({ $0.action })
        // Select the initial segment
        segmentedControl.selectedSegmentIndex = viewModel.selectedSegmentIndex ?? UISegmentedControlNoSegment
    }

    // MARK: - Target Action

    @objc
    func segmentedControlValueChanged() {
        let action = actions[segmentedControl.selectedSegmentIndex]
        dispatchAction?(action)
    }
}
