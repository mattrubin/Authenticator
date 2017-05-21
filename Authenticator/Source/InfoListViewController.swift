//
//  InfoListViewController.swift
//  Authenticator
//
//  Copyright (c) 2017 Authenticator authors
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

class InfoListViewController: UITableViewController {
    private var viewModel: InfoList.ViewModel
    private let dispatchAction: (InfoList.Effect) -> Void

    // MARK: Initialization

    init(viewModel: InfoList.ViewModel, dispatchAction: @escaping (InfoList.Effect) -> Void) {
        self.viewModel = viewModel
        self.dispatchAction = dispatchAction
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateWithViewModel(_ viewModel: InfoList.ViewModel) {
        self.viewModel = viewModel
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
    }

    // MARK: Target Actions

    func done() {
        dispatchAction(.done)
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rowModels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithClass(InfoListCell.self)
        updateCell(cell, forRowAtIndexPath: indexPath)
        return cell
    }

    fileprivate func updateCell(_ cell: InfoListCell, forRowAtIndexPath indexPath: IndexPath) {
        let rowModel = viewModel.rowModels[indexPath.row]
        cell.updateWithRowModel(rowModel)
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowModel = viewModel.rowModels[indexPath.row]
        dispatchAction(rowModel.action)
    }
}

class InfoListCell: UITableViewCell {
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    var customConstraints: [NSLayoutConstraint]?

    // MARK: Initialization

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        configureCell()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureCell()
    }

    private func configureCell() {
        backgroundColor = .otpBackgroundColor
        selectionStyle = .none

        titleLabel.textColor = .otpForegroundColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        descriptionLabel.textColor = .otpForegroundColor
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)

        setNeedsUpdateConstraints()
    }

    override func updateConstraints() {
        if customConstraints == nil {
            let newConstraints = [
                titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
                titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                titleLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor),
                descriptionLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                descriptionLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                descriptionLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            ]
            contentView.addConstraints(newConstraints)
            customConstraints = newConstraints
        }

        // "Important: Call [super updateConstraints] as the final step in your implementation."
        super.updateConstraints()
    }

    // MARK: Update

    func updateWithRowModel(_ rowModel: InfoList.RowModel) {
        titleLabel.text = rowModel.title
        descriptionLabel.attributedText = rowModel.description
    }
}
