//
//  QRScanner.swift
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

import AVFoundation

protocol QRScannerDelegate: class {
    func handleDecodedText(_ text: String)
    func handleError(_ error: Error)
}

class QRScanner: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: QRScannerDelegate?
    fileprivate let serialQueue = DispatchQueue(label: "QRScanner serial queue", attributes: [])
    fileprivate lazy var captureSession: AVCaptureSession? = {
        do {
            return try QRScanner.createCaptureSessionWithDelegate(self)
        } catch {
            DispatchQueue.main.async {
                self.delegate?.handleError(error)
            }
            return nil
        }
    }()

    func start(_ completion: (AVCaptureSession?) -> Void) {
        serialQueue.async {
            self.captureSession?.startRunning()
            DispatchQueue.main.async {
                completion(self.captureSession)
            }
        }
    }

    func stop() {
        serialQueue.async {
            self.captureSession?.stopRunning()
        }
    }

    // MARK: Capture

    enum CaptureSessionError: Error {
        case inputError
        case outputError
    }

    fileprivate class func createCaptureSessionWithDelegate(_ delegate: AVCaptureMetadataOutputObjectsDelegate) throws -> AVCaptureSession {
        let captureSession = AVCaptureSession()

        guard let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo),
            let captureInput = try? AVCaptureDeviceInput(device: captureDevice) else {
                throw CaptureSessionError.inputError
        }
        captureSession.addInput(captureInput)

        let captureOutput = AVCaptureMetadataOutput()
        // The output must be added to the session before it can be checked for metadata types
        captureSession.addOutput(captureOutput)
        guard let availableTypes = captureOutput.availableMetadataObjectTypes
            where (availableTypes as NSArray).contains(AVMetadataObjectTypeQRCode) else {
                throw CaptureSessionError.outputError
        }
        captureOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        captureOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)

        return captureSession
    }

    class var deviceCanScan: Bool {
        return (AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) != nil)
    }

    // MARK: AVCaptureMetadataOutputObjectsDelegate

    func captureOutput(_ captureOutput: AVCaptureOutput?, didOutputMetadataObjects metadataObjects: [Any]?, from connection: AVCaptureConnection?) {
        guard let metadataObjects = metadataObjects else {
            return
        }

        for metadata in metadataObjects {
            if let metadata = metadata as? AVMetadataMachineReadableCodeObject
                where metadata.type == AVMetadataObjectTypeQRCode,
                let string = metadata.stringValue {
                    // Dispatch to the main queue because setMetadataObjectsDelegate doesn't
                    DispatchQueue.main.async {
                        self.delegate?.handleDecodedText(string)
                    }
            }
        }
    }
}
