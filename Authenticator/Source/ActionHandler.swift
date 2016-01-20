//
//  ActionHandler.swift
//  Authenticator
//
//  Copyright (c) 2015 Authenticator authors
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

import OneTimePassword

enum AppAction {
    case BeginTokenEntry
    case BeginManualTokenEntry
    case CancelTokenEntry
    case SaveNewToken(Token)

    case BeginTokenEdit(PersistentToken)
    case CancelTokenEdit
    case SaveChanges(Token, PersistentToken)

    case AddTokenFromURL(Token)

    case TokenListAction(TokenList.Action)
    case TokenEntryFormAction(TokenEntryForm.Action)
    case TokenEditFormAction(TokenEditForm.Action)

    case UpdateToken(PersistentToken)
    case MoveToken(fromIndex: Int, toIndex: Int)
    case DeleteTokenAtIndex(Int)
}

protocol ActionHandler: class {
    func handleAction(action: AppAction)
}
