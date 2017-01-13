//
//  TokenScannerViewController.swift
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

import UIKit
import AVFoundation
import OneTimePassword

class TokenScannerViewController: UIViewController, QRScannerDelegate {
    private let scanner = QRScanner()
    private let videoLayer = AVCaptureVideoPreviewLayer()

    private var viewModel: TokenScanner.ViewModel
    private let dispatchAction: (TokenScanner.Action) -> Void

    // MARK: Initialization

    init(viewModel: TokenScanner.ViewModel, dispatchAction: (TokenScanner.Action) -> Void) {
        self.viewModel = viewModel
        self.dispatchAction = dispatchAction
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateWithViewModel(viewModel: TokenScanner.ViewModel) {
        self.viewModel = viewModel
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.blackColor()

        title = "Scan Token"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Cancel,
            target: self,
            action: #selector(TokenScannerViewController.cancel)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Compose,
            target: self,
            action: #selector(TokenScannerViewController.addTokenManually)
        )

        videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoLayer)

        if Process.isDemo {
            // If this is a demo, display an image in place of the AVCaptureVideoPreviewLayer.
            let imageView = UIImageView(frame: view.bounds)
            imageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            imageView.contentMode = .ScaleAspectFill
            imageView.image = UIImage.demoScannerImage()
            view.addSubview(imageView)
        }

        let overlayView = ScannerOverlayView(frame: view.bounds)
        view.addSubview(overlayView)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        scanner.delegate = self
        scanner.start { captureSession in
            self.videoLayer.session = captureSession
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        scanner.stop()
    }

    // MARK: Target Actions

    func cancel() {
        dispatchAction(.Cancel)
    }

    func addTokenManually() {
        dispatchAction(.BeginManualTokenEntry)
    }

    // MARK: QRScannerDelegate

    func handleDecodedText(text: String) {
        guard viewModel.isScanning else {
            return
        }
        dispatchAction(.ScannerDecodedText(text))
    }

    func handleError(error: ErrorType) {
        dispatchAction(.ScannerError(error))
    }
}
