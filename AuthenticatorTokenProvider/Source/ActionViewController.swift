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

@objc(ActionViewController)

class ActionViewController: UIViewController {

    lazy var extensionController: ExtensionController = {
        return ExtensionController(withContext: self.extensionContext!)
    }()

    override func viewDidLoad() {
        // Get context from the webpage to highlight potential passwords first
        super.viewDidLoad()
        present(extensionController.rootViewController, animated: false, completion: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.extensionController.rootViewController.preferredStatusBarStyle
    }

    override func loadView() {
        self.view = UIView(frame: UIScreen.main.bounds)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

