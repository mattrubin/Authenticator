//
//  WatchTokenStore.swift
//  Authenticator
//
//  Copyright (c) 2013-2016 Authenticator authors
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

import Foundation
import OneTimePassword
import WatchConnectivity

extension TokenStore {

    func onReachable() {
        // always request tokens to know we have the latest
        requestTokens()
    }

    // watch app request tokens to be pushed from the
    // phone. done when we launch the app.
    func requestTokens() {
        simpleSend(kRequestTokensMessage)
    }

    // invoked when we receive tokens from the phone,
    // both when we've requested it and when they are
    // automatically pushed.
    func receivePersistentTokensMessage(data: NSData) {
        guard let arr = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [NSURL] else {
            print("could not parse NSData to NSURL")
            return
        }
        let tokens = arr.map() { Token(url: $0)! }

        do {
            try resetTokens(tokens)
        } catch {
            // XXX keychain storage errors end up here,
            // perhaps show some error message to the user?
            print("resetTokens failed with \(error)")
        }
    }

}



// MARK: - WatchConnectivity

extension TokenStore : WCSessionDelegate {

    func activateWCSession() {
        // is the framework available?
        guard WCSession.isSupported() else {
            return
        }
        let session = WCSession.defaultSession()
        session.delegate = self // before activate
        session.activateSession()
    }

    func session(session: WCSession, activationDidCompleteWithState
                 activationState: WCSessionActivationState, error: NSError?) {
        switch activationState {
        case .NotActivated:
            // not much we can don about that
            print("Session is not actived")
        case .Inactive:
            // this is a transitional state from activated -> not activated
            print("Session is inactive")
        case .Activated:
            // All is good
            if session.reachable {
                onReachable()
            }
        }
    }

    func sessionReachabilityDidChange(session: WCSession) {
        if session.reachable {
            onReachable()
        }
    }

    private var session: WCSession? {
        // is the framework available at all?
        guard WCSession.isSupported() else {
            return nil
        }
        let session = WCSession.defaultSession()
        // can we use it to communicate?
        guard session.activationState == .Activated else {
            return nil
        }
        return session
    }

    // validation free simple send and forget
    func simpleSend(name: String) {
        session?.sendMessage(["name":name], replyHandler: nil, errorHandler: nil)
    }

    // messages are on the form:
    // [
    //    name: "OTPPersistentTokensMessage"   // name of message
    //    data: ...                            // payload
    // ]
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        guard let name = message["name"] as? String else {
            print("name cant be read as string")
            return
        }
        switch name {
        case kTokensMessage:
            guard let data = message["data"] as? NSData else {
                print("message not containing expected data")
                return
            }
            receivePersistentTokensMessage(data)
        default:
            print("Received message with unknown name ", name)
        }
    }

}
