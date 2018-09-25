//
//  DisplayOptions.swift
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

struct DisplayOptions: TableViewModelRepresentable {
    // MARK: View Model

    typealias ViewModel = TableViewModel<DisplayOptions>

    enum HeaderModel {}

    enum RowModel: Identifiable {
        case segmentedControlRow(identity: String, viewModel: SegmentedControlRowViewModel<Action>)

        func hasSameIdentity(as other: RowModel) -> Bool {
            switch (self, other) {
            case let (.segmentedControlRow(rowA), .segmentedControlRow(rowB)):
                return rowA.identity == rowB.identity
            }
        }
    }

    func viewModel(digitGroupSize: Int) -> ViewModel {
        return TableViewModel(
            title: "Display Options",
            rightBarButton: BarButtonViewModel(style: .done, action: .done),
            sections: [[digitGroupRowModel(currentValue: digitGroupSize)]],
            doneKeyAction: .done
        )
    }

    private func digitGroupRowModel(currentValue: Int) -> RowModel {
        return .segmentedControlRow(
            identity: "password.digitGroupSize",
            viewModel: SegmentedControlRowViewModel(
                options: [(title: "•• •• ••", value: 2), (title: "••• •••", value: 3)],
                value: currentValue,
                changeAction: DisplayOptions.Effect.setDigitGroupSize
            )
        )
    }

    // MARK: Actions

    enum Effect {
        case setDigitGroupSize(Int)
        case done
    }

    typealias Action = Effect
}
