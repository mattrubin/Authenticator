//
//  OTPScannerViewController.swift
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

protocol ScannerViewControllerDelegate: class {
    func scannerDidCancel(scanner: AnyObject)
    func scanner(scanner: AnyObject, didCreateToken token: OTPToken)
}

class OTPScannerViewController: UIViewController, QRScannerDelegate, TokenEntryFormDelegate {
    weak var delegate: ScannerViewControllerDelegate?
    private let scanner: QRScanner
    private var videoLayer: AVCaptureVideoPreviewLayer?

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

        self.view.backgroundColor = UIColor.blackColor()

        self.title = "Scan Token"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Cancel,
            target: self,
            action: Selector("cancel")
        )
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Compose,
            target: self,
            action: Selector("addTokenManually")
        )

        self.videoLayer = AVCaptureVideoPreviewLayer()
        self.videoLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.view.layer.addSublayer(self.videoLayer!)
        self.videoLayer!.frame = self.view.layer.bounds

        let overlayView = OTPScannerOverlayView(frame: self.view.bounds)
        self.view.addSubview(overlayView)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.scanner.start() { captureSession in
            self.videoLayer?.session = captureSession
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.scanner.stop(nil)
    }

    // MARK: Target Actions

    func cancel() {
        self.delegate?.scannerDidCancel(self)
    }

    func addTokenManually() {
        let form = TokenEntryForm(delegate: self)
        let entryController = TokenFormViewController(form: form)
        self.navigationController?.pushViewController(entryController, animated: true)
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
        self.scanner.stop(nil)

        // Inform the delegate that an auth URL was captured
        self.delegate?.scanner(self, didCreateToken: token)
    }

    func handleError(error: NSError) {
        print("Error: \(error)")
        SVProgressHUD.showErrorWithStatus("Capture Failed")
    }

    // MARK: TokenEntryFormDelegate

    func entryFormDidCancel(form: TokenEntryForm) {
        self.delegate?.scannerDidCancel(form)
    }

    func form(form: TokenEntryForm, didCreateToken token: OTPToken) {
        // Forward didCreateToken on to the scanner's delegate
        self.delegate?.scanner(form, didCreateToken: token)
    }
}
