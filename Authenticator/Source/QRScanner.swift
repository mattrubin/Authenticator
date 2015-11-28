//
//  QRScanner.swift
//  Authenticator
//
//  Copyright (c) 2015 Matt Rubin
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

protocol QRScannerDelegate: class {
    func handleDecodedText(text: String)
    func handleError(error: ErrorType)
}

class QRScanner: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: QRScannerDelegate?
    private let serialQueue = dispatch_queue_create("QR Scanner serial queue",
        DISPATCH_QUEUE_SERIAL)
    private lazy var captureSession: AVCaptureSession? = {
        do {
            return try QRScanner.createCaptureSessionWithDelegate(self)
        } catch {
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.handleError(error)
            }
            return nil
        }
    }()

    func start(completion: AVCaptureSession? -> ()) {
        dispatch_async(serialQueue) {
            self.captureSession?.startRunning()
            dispatch_async(dispatch_get_main_queue()) {
                completion(self.captureSession)
            }
        }
    }

    func stop() {
        dispatch_async(serialQueue) {
            self.captureSession?.stopRunning()
        }
    }

    // MARK: Capture

    enum CaptureSessionError: ErrorType {
        case InputError
        case OutputError
    }

    private class func createCaptureSessionWithDelegate(delegate: AVCaptureMetadataOutputObjectsDelegate) throws -> AVCaptureSession {
        let captureSession = AVCaptureSession()

        guard let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo),
            let captureInput = try? AVCaptureDeviceInput(device: captureDevice) else {
                throw CaptureSessionError.InputError
        }
        captureSession.addInput(captureInput)

        let captureOutput = AVCaptureMetadataOutput()
        // The output must be added to the session before it can be checked for metadata types
        captureSession.addOutput(captureOutput)
        guard let availableTypes = captureOutput.availableMetadataObjectTypes
            where (availableTypes as NSArray).containsObject(AVMetadataObjectTypeQRCode) else {
                throw CaptureSessionError.OutputError
        }
        captureOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        captureOutput.setMetadataObjectsDelegate(delegate, queue: dispatch_get_main_queue())

        return captureSession
    }

    class var deviceCanScan: Bool {
        return (AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) != nil)
    }

    // MARK: AVCaptureMetadataOutputObjectsDelegate

    func captureOutput(captureOutput: AVCaptureOutput?, didOutputMetadataObjects metadataObjects: [AnyObject]?, fromConnection connection: AVCaptureConnection?) {
        guard let metadataObjects = metadataObjects else {
            return
        }

        for metadata in metadataObjects {
            if let metadata = metadata as? AVMetadataMachineReadableCodeObject
                where metadata.type == AVMetadataObjectTypeQRCode,
                let string = metadata.stringValue {
                    // Dispatch to the main queue because setMetadataObjectsDelegate doesn't
                    dispatch_async(dispatch_get_main_queue()) {
                        self.delegate?.handleDecodedText(string)
                    }
            }
        }
    }
}
