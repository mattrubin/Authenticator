//
//  Auth.swift
//  Authenticator
//
//  Copyright (c) 2017-2018 Authenticator authors
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

struct Auth: Component {
    private var state: State

    private enum State: Equatable {
        case unlocked
        case locked(shouldAuthenticateAutomatically: Bool)

        var isLocked: Bool {
            switch self {
            case .unlocked:
                return false
            case .locked:
                return true
            }
        }
    }

    init(screenLockEnabled: Bool) {
        if screenLockEnabled {
            state = .locked(shouldAuthenticateAutomatically: true)
        } else {
            state = .unlocked
        }
    }

    // MARK: View

    struct ViewModel {
        var enabled: Bool
    }

    var viewModel: ViewModel {
        return ViewModel(enabled: state.isLocked)
    }

    // MARK: Update

    enum Action {
        case tryToUnlock
    }

    enum Effect {
        case authenticateUser(success: Event, failure: (Error) -> Event)
    }

    enum Event {
        case applicationDidBecomeActive
        case applicationWillResignActive

        case authenticationSucceeded
        case authenticationFailed(Error)
    }

    mutating func update(with action: Action) throws -> Effect? {
        switch action {
        case .tryToUnlock:
            return .authenticateUser(success: .authenticationSucceeded,
                                     failure: Event.authenticationFailed)
        }
    }

    mutating func update(with event: Event) -> Effect? {
        switch event {
        case .applicationDidBecomeActive:
            if case .locked(shouldAuthenticateAutomatically: true) = state {
                return .authenticateUser(success: .authenticationSucceeded,
                                         failure: Event.authenticationFailed)
            } else {
                return nil
            }

        case .applicationWillResignActive:
            // When the app becomes inactive, regardless of the current state, the app should lock and prepare to
            // automatically authenticate when the app becomes active.
            state = .locked(shouldAuthenticateAutomatically: true)
            return nil

        case .authenticationSucceeded:
            state = .unlocked
            return nil

        case .authenticationFailed(let error):
            // If automatic authentication fails, the app should remain locked, but should not automatically try to
            // authenticate again.
            if case .locked(shouldAuthenticateAutomatically: true) = state {
                state = .locked(shouldAuthenticateAutomatically: false)
            }
            print(error) // TODO: Improve error handling
            return nil
        }
    }
}
