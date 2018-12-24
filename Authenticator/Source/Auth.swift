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
    var authAvailable: Bool = false
    var authRequired: Bool = false

    // MARK: View

    struct ViewModel {
        var enabled: Bool
    }

    var viewModel: ViewModel {
        return ViewModel(enabled: authAvailable && authRequired)
    }

    // MARK: Update

    enum Action {
        case enableLocalAuth(isEnabled: Bool)
        case enablePrivacy
        case tryToUnlock
    }

    enum Effect {
        case authenticateUser(success: Event, failure: (Error) -> Event)
    }

    enum Event {
        case authenticationSucceeded
        case authenticationFailed(Error)
    }

    mutating func update(with action: Action) throws -> Effect? {
        switch action {
        case .enableLocalAuth(let isEnabled):
            return try handleEnableLocalAuth(isEnabled)

        case .enablePrivacy:
            authRequired = true
            return nil

        case .tryToUnlock:
            return .authenticateUser(success: .authenticationSucceeded,
                                     failure: Event.authenticationFailed)
        }
    }

    mutating func update(with event: Event) -> Effect? {
        switch event {
        case .authenticationSucceeded:
            authRequired = false
            return nil

        case .authenticationFailed(let error):
            print(error) // TODO: Improve error handling
            return nil
        }
    }

    private mutating func handleEnableLocalAuth(_ shouldEnable: Bool ) throws -> Effect? {
        // no change, no effect
        if authAvailable == shouldEnable {
            return nil
        }
        authAvailable = shouldEnable

        // enabling after not being enabled, show privacy screen
        if authAvailable {
            return try update(with: .enablePrivacy)
        }
        return nil
    }

}
