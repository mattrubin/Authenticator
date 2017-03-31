//
//  SegmentedControlRow.swift
//  Authenticator
//
//  Copyright (c) 2014-2016 Authenticator authors
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

struct SegmentedControlRowViewModel<Action> {
    let segments: [(title: String, action: Action)]
    let selectedSegmentIndex: Int?

    init<V: Equatable>(options: [(title: String, value: V)], value: V, changeAction: (V) -> Action) {
        segments = options.map({ option in
            (title: option.title, action: changeAction(option.value))
        })
        selectedSegmentIndex = options.map({ $0.value }).index(of: value)
    }
}

// "static stored properties not yet supported in generic types"
private let preferredHeight: CGFloat = 54

class SegmentedControlRowCell<Action>: UITableViewCell {
    var dispatchAction: ((Action) -> Void)?

    fileprivate let segmentedControl = UISegmentedControl()
    fileprivate var actions: [Action] = []

    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubviews()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureSubviews()
    }

    // MARK: - Subviews

    fileprivate func configureSubviews() {
        contentView.addSubview(segmentedControl)
        let action = #selector(SegmentedControlRowCell.segmentedControlValueChanged)
        segmentedControl.addTarget(self, action: action, for: .valueChanged)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let margin: CGFloat = 20
        let width = contentView.bounds.width - (2 * margin)
        segmentedControl.frame = CGRect(x: margin, y: 15, width: width, height: 29)
    }

    // MARK: - View Model

    func updateWithViewModel(_ viewModel: SegmentedControlRowViewModel<Action>) {
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

    static func heightWithViewModel(_ viewModel: SegmentedControlRowViewModel<Action>) -> CGFloat {
        return preferredHeight
    }

    // MARK: - Target Action

    func segmentedControlValueChanged() {
        let action = actions[segmentedControl.selectedSegmentIndex]
        dispatchAction?(action)
    }
}
