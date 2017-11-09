//
//  ActionViewController.swift
//  AuthenticatorTokenProvider
//
//  Created by Beau Collins on 11/9/17.
//  Copyright © 2017 Matt Rubin. All rights reserved.
//

import UIKit
import Foundation
import MobileCoreServices
import OneTimePassword

@objc(ActionViewController)

class ActionViewController: UITableViewController {

    let store: TokenStore

    var viewModel: TokenListViewModel
    var nextRefreshTime: Date = Date.distantPast
    let component: TokenList = TokenList()

    override init(style: UITableViewStyle) {
        do {
            store = try KeychainTokenStore(
                keychain: Keychain.sharedInstance,
                userDefaults: UserDefaults.standard
            )
        } catch {
            // If the TokenStore could not be created, the app is unusable.
            fatalError("Failed to load token store: \(error)")
        }
        (viewModel, nextRefreshTime) = component.viewModel(for: store.persistentTokens, at: DisplayTime(date: Date()))
        super.init(style: style)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Authenticator"
        self.view.backgroundColor = UIColor.otpBackgroundColor

        // Configure table view
        self.tableView.separatorStyle = .none
        self.tableView.indicatorStyle = .white
        self.tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        self.tableView.allowsSelectionDuringEditing = true

        // Get context from the webpage to highlight potential passwords first
        for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
            print("Input item \(item.attachments ?? [])")
            if let provider = item.attachments?.first as? NSItemProvider {
                provider.loadItem(forTypeIdentifier: kUTTypePropertyList as String, options: nil) { (data, error) in
                    guard error == nil else {
                        print("failure \(error)")
                        return
                    }
                    guard let result = data as? NSDictionary else {
                        print("not valid data")
                        return;
                    }
                    print("Provider: \(result["baseURI"] ?? "no uri")")
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rowModels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithClass(TokenRowCell.self)
        updateCell(cell, forRowAtIndexPath: indexPath)
        return cell
    }

    fileprivate func updateCell(_ cell: TokenRowCell, forRowAtIndexPath indexPath: IndexPath) {
        let rowModel = viewModel.rowModels[indexPath.row]
        cell.updateWithRowModel(rowModel)
        // cell.dispatchAction = dispatchAction
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowModel = viewModel.rowModels[indexPath.row]
        if isEditing {
            dispatchAction(rowModel.editAction)
        } else {
            dispatchAction(rowModel.selectAction)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

    func dispatchAction(_ action: TokenList.Action) {
        switch action {
        case .copyPassword(let password):
            self.providePassword(password)
        default:
            print("action not handled \(action)")
        }
    }

    func providePassword(_ password: String) {
        let item = NSExtensionItem()
        let contents: NSDictionary = [
            NSExtensionJavaScriptFinalizeArgumentKey: ["password" : password ]
        ]
        let passwordItemProvider = NSItemProvider(item: contents, typeIdentifier: kUTTypePropertyList as String)
        item.attachments = [passwordItemProvider]
        self.extensionContext!.completeRequest(returningItems: [item])
    }

}

