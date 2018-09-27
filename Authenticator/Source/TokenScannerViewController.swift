//
//  TokenScannerViewController.swift
//  Authenticator
//
//  Copyright (c) 2013-2018 Authenticator authors
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

final class TokenScannerViewController: UIViewController, QRScannerDelegate {
    private let scanner = QRScanner()
    private let videoLayer = AVCaptureVideoPreviewLayer()

    private var viewModel: TokenScanner.ViewModel
    private let dispatchAction: (TokenScanner.Action) -> Void

    private let permissionLabel: UILabel = {
        let linkTitle = "Go to Settings →"
        let message = "To add a new token via QR code, Authenticator needs permission to access the camera.\n\(linkTitle)"
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.3
        paragraphStyle.paragraphSpacing = 5
        let attributedMessage = NSMutableAttributedString(string: message, attributes: [
            .font: UIFont.systemFont(ofSize: 15, weight: .light),
            .paragraphStyle: paragraphStyle,
        ])
        attributedMessage.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 15),
                                       range: (attributedMessage.string as NSString).range(of: linkTitle))

        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = attributedMessage
        label.textAlignment = .center
        label.textColor = UIColor.otpForegroundColor
        return label
    }()

    private lazy var permissionButton: UIButton = {
        let button = UIButton(frame: UIScreen.main.bounds)
        button.backgroundColor = .black
        button.addTarget(self, action: #selector(TokenScannerViewController.editPermissions), for: .touchUpInside)

        self.permissionLabel.frame = button.bounds.insetBy(dx: 35, dy: 35)
        self.permissionLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        button.addSubview(self.permissionLabel)

        button.accessibilityLabel = "To add a new token via QR code, Authenticator needs permission to access the camera."
        button.accessibilityHint = "Double-tap to go to Settings."

        return button
    }()

    // MARK: Initialization

    init(viewModel: TokenScanner.ViewModel, dispatchAction: @escaping (TokenScanner.Action) -> Void) {
        self.viewModel = viewModel
        self.dispatchAction = dispatchAction
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with viewModel: TokenScanner.ViewModel) {
        self.viewModel = viewModel
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black

        title = "Scan Token"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(TokenScannerViewController.cancel)
        )
        let manualEntryBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .compose,
            target: self,
            action: #selector(TokenScannerViewController.addTokenManually)
        )
        manualEntryBarButtonItem.accessibilityLabel = "Manual token entry"
        navigationItem.rightBarButtonItem = manualEntryBarButtonItem

        videoLayer.videoGravity = .resizeAspectFill
        videoLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoLayer)

        permissionButton.frame = view.bounds
        permissionButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        permissionButton.isHidden = true
        view.addSubview(permissionButton)

        if CommandLine.isDemo {
            // If this is a demo, display an image in place of the AVCaptureVideoPreviewLayer.
            let imageView = UIImageView(frame: view.bounds)
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.contentMode = .scaleAspectFill
            imageView.image = UIImage.demoScannerImage()
            view.addSubview(imageView)
        }

        let overlayView = ScannerOverlayView(frame: view.bounds)
        overlayView.isUserInteractionEnabled = false
        view.addSubview(overlayView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        switch QRScanner.authorizationStatus {
        case .notDetermined:
            QRScanner.requestAccess { [weak self] accessGranted in
                if accessGranted {
                    self?.startScanning()
                } else {
                    self?.showMissingAccessMessage()
                }
            }
        case .authorized:
            startScanning()
        case .denied:
            showMissingAccessMessage()
        case .restricted:
            // There's nothing we can do if camera access is restricted.
            // This should only ever be reached if camera restrictions are changed while the app is running, because if
            // the app is launched with restrictions already enabled, the deviceCanScan check will retrun false.
            dispatchAction(.beginManualTokenEntry)
        }
    }

    private func startScanning() {
        scanner.delegate = self
        scanner.start(success: { [weak self] captureSession in
            self?.videoLayer.session = captureSession
        }, failure: { [weak self] error in
            self?.dispatchAction(.scannerError(error))
        })
    }

    private func showMissingAccessMessage() {
        permissionButton.isHidden = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scanner.stop()
    }

    // MARK: Target Actions

    @objc
    func cancel() {
        dispatchAction(.cancel)
    }

    @objc
    func addTokenManually() {
        dispatchAction(.beginManualTokenEntry)
    }

    @objc
    func editPermissions() {
        dispatchAction(.showApplicationSettings)
    }

    // MARK: QRScannerDelegate

    private var lastScanTime = Date(timeIntervalSince1970: 0)
    private let minimumScanInterval: TimeInterval = 1

    func handleDecodedText(_ text: String) {
        guard viewModel.isScanning else {
            return
        }

        let now = Date()
        if now.timeIntervalSince(lastScanTime) > minimumScanInterval {
            lastScanTime = now
            dispatchAction(.scannerDecodedText(text))
        }
    }
}
