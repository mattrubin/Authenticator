//
//  WCSessionDelegate.swift
//  Authenticator
//
//  Copyright (c) 2016 Authenticator authors
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

// MARK: - WatchConnectivity

@available(iOS 9.0, *)
extension TokenStore: WCSessionDelegate {

    func activateWCSession() {
        guard WCSession.isSupported() else {
            return
        }
        let session = WCSession.defaultSession()
        session.delegate = self // before activate
        session.activateSession()
    }

    // We're not interested in the life cycle of the
    // watch connection. Hence, these methods are just
    // empty placeholders to fulfill the protocol.
    @available(iOS 9.3, *)
    func session(session: WCSession, activationDidCompleteWithState
        activationState: WCSessionActivationState, error: NSError?) {
    }
    func sessionDidBecomeInactive(session: WCSession) {
    }
    func sessionDidDeactivate(session: WCSession) {
    }

    private var session: WCSession? {
        // is the framework available at all?
        guard WCSession.isSupported() else {
            return nil
        }
        let session = WCSession.defaultSession()
        if #available(iOS 9.3, *) {
            // can we use it to communicate?
            guard session.activationState == .Activated else {
                return nil
            }
        }
        return session
    }

    func sendTokens() throws {
        // we transport the tokens as [NSURL, NSURL, NSURL, ...]
        let urls = try persistentTokens.map() { try $0.token.toURLWithSecret() }
        // converted to NSData
        let data = NSKeyedArchiver.archivedDataWithRootObject(urls)
        // and ship it
        simpleSendData(kTokensMessage, data: data)
    }

    // validation free simple send and forget
    func simpleSendData(name: String, data: NSData) {
        session?.sendMessage(["name":name, "data":data], replyHandler: nil, errorHandler: {
            // not much of a problem, because we don't really care
            print("sendMessage failed \($0)")
        })
    }

    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        guard let name = message["name"] as? String else {
            print("name could not be read as string")
            return
        }
        switch name {
        case kRequestTokensMessage:
            // watch wants tokens
            do {
                try sendTokens()
            } catch {
                print("sendTokens from request failed \(error)")
            }
        default:
            print("Received message with unknown name ", name)
        }
    }

}

private extension Token {
    private func toURLWithSecret() throws -> NSURL {
        let originalURL = try self.toURL()
        guard let urlComponents = NSURLComponents(URL: originalURL, resolvingAgainstBaseURL: false)
            else { throw SecretSerializationError() }
        let secretQueryItem = NSURLQueryItem(name: "secret", value: generator.secret.base32String())
        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(secretQueryItem)
        urlComponents.queryItems = queryItems

        guard let url = urlComponents.URL else {
            throw SecretSerializationError()
        }
        return url
    }

    private struct SecretSerializationError: ErrorType {}
}
