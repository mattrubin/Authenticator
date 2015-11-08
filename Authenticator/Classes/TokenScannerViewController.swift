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

import AVFoundation
import OneTimePasswordLegacy

protocol ScannerViewControllerDelegate: class, TokenEntryFormDelegate {
    func scannerDidCancel(scanner: AnyObject)
    func scanner(scanner: AnyObject, didCreateToken token: OTPToken)
}

class TokenScannerViewController: UIViewController, QRScannerDelegate {
    weak var delegate: ScannerViewControllerDelegate?
    private let scanner: QRScanner
    private let videoLayer = AVCaptureVideoPreviewLayer()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        scanner = QRScanner()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        scanner.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        scanner = QRScanner()
        super.init(coder: aDecoder)
        scanner.delegate = self
    }

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
        delegate?.scannerDidCancel(self)
    }

    func addTokenManually() {
        guard let delegate = delegate
            else { return }
        let form = TokenEntryForm(delegate: delegate)
        let entryController = TokenFormViewController(form: form)
        navigationController?.pushViewController(entryController, animated: true)
    }

    // MARK: QRScannerDelegate

    func handleDecodedText(text: String) {
        // Attempt to create a token from the decoded text
        guard let url = NSURL(string: text),
            let token = OTPToken.tokenWithURL(url)
            else {
                // Show an error message
                SVProgressHUD.showErrorWithStatus("Invalid Token")
                return
        }

        // Halt the video capture
        scanner.stop()
        // Inform the delegate that an auth URL was captured
        delegate?.scanner(self, didCreateToken: token)
    }

    func handleError(error: ErrorType) {
        print("Error: \(error)")
        SVProgressHUD.showErrorWithStatus("Capture Failed")
    }
}
