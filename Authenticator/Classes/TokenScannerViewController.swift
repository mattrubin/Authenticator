//
//  TokenScannerViewController.swift
//  Authenticator
//
//  Copyright (c) 2013 Matt Rubin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit
import AVFoundation
import OneTimePassword
import SVProgressHUD

class TokenScannerViewController: UIViewController, QRScannerDelegate {
    private let scanner = QRScanner()
    private let videoLayer = AVCaptureVideoPreviewLayer()

    // MARK: Events

    enum Event {
        case Cancel
        case Save(Token)
    }

    // In an ideal world, this would be a non-optional constant, but making it an optional var
    // avoids needing to implement initializers.
    var callback: ((Event) -> ())?

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.blackColor()

        title = "Scan Token"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Cancel,
            target: self,
            action: Selector("cancel")
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Compose,
            target: self,
            action: Selector("addTokenManually")
        )

        videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoLayer)

        let overlayView = ScannerOverlayView(frame: view.bounds)
        view.addSubview(overlayView)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        scanner.delegate = self
        scanner.start() { captureSession in
            self.videoLayer.session = captureSession
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        scanner.stop()
    }

    // MARK: Target Actions

    func cancel() {
        callback?(.Cancel)
    }

    func addTokenManually() {
        let form = TokenEntryForm() { [callback] (event) in
            switch event {
            case .Cancel:
                callback?(.Cancel)
            case .Save(let token):
                callback?(.Save(token))
            }
        }
        let entryController = TokenFormViewController(form: form)
        navigationController?.pushViewController(entryController, animated: true)
    }

    // MARK: QRScannerDelegate

    func handleDecodedText(text: String) {
        // Attempt to create a token from the decoded text
        guard let url = NSURL(string: text),
            let token = Token.URLSerializer.deserialize(url) else {
                // Show an error message
                SVProgressHUD.showErrorWithStatus("Invalid Token")
                return
        }

        // Halt the video capture
        scanner.stop()
        // Inform the delegate that an auth URL was captured
        callback?(.Save(token))
    }

    func handleError(error: ErrorType) {
        print("Error: \(error)")
        SVProgressHUD.showErrorWithStatus("Capture Failed")
    }
}
