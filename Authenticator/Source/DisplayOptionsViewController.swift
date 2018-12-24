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
    fileprivate let dispatchAction: (DisplayOptions.Effect) -> Void
    fileprivate var viewModel: DisplayOptions.ViewModel

    private let digitGroupingRowCell = DigitGroupingRowCell<DisplayOptions.Effect>()

    init(viewModel: DisplayOptions.ViewModel, dispatchAction: @escaping (DisplayOptions.Effect) -> Void) {
        self.viewModel = viewModel
        self.dispatchAction = dispatchAction
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
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
        title = "Display Options"

        let action = #selector(DisplayOptionsViewController.rightBarButtonAction)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: action)
    }

    // MARK: - Target Actions

    @objc
    func rightBarButtonAction() {
        dispatchAction(.done)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section == 0 else {
            return 0
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            digitGroupingRowCell.update(with: digitGroupingRowViewModel)
            digitGroupingRowCell.dispatchAction = dispatchAction
            return digitGroupingRowCell
        default:
            return UITableViewCell()
        }
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
    func update(with viewModel: DisplayOptions.ViewModel) {
        self.viewModel = viewModel
        digitGroupingRowCell.update(with: digitGroupingRowViewModel)
    }

    fileprivate var digitGroupingRowViewModel: DigitGroupingRowViewModel<DisplayOptions.Effect> {
        return DigitGroupingRowViewModel(
            title: "Digit Grouping",
            options: [
                (title: "•• •• ••", value: 2, accessibilityLabel: "Groups of two digits", accessibilityHint: "For example, 38 62 47"),
                (title: "••• •••", value: 3, accessibilityLabel: "Groups of three digits", accessibilityHint: "For example, 386 247"),
            ],
            value: viewModel.digitGroupSize,
            changeAction: DisplayOptions.Effect.setDigitGroupSize
        )
    }
}

// MARK: Digit Grouping Row

// swiftlint:disable large_tuple
struct DigitGroupingRowViewModel<Action> {
    let title: String
    let segments: [(title: String, accessibilityLabel: String, accessibilityHint: String, action: Action)]
    let selectedSegmentIndex: Int?

    init<V: Equatable>(title: String, options: [(title: String, value: V, accessibilityLabel: String, accessibilityHint: String)], value: V, changeAction: (V) -> Action) {
        self.title = title
        segments = options.map({ option in
            (title: option.title, accessibilityLabel: option.accessibilityLabel, accessibilityHint: option.accessibilityHint, action: changeAction(option.value))
        })
        selectedSegmentIndex = options.map({ $0.value }).index(of: value)
    }
}
// swiftlint:enable large_tuple

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

        accessibilityHint = "The digits of a password can be shown in different sized groups."

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

            // This is a hack to set the accessibility label on each segment, but for now it works.
            // If a future iOS update ever changes the internals of UISegmentedControl, this may break horribly.
            segmentedControl.subviews.last?.accessibilityLabel = segment.accessibilityLabel
            segmentedControl.subviews.last?.accessibilityHint = segment.accessibilityHint
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
