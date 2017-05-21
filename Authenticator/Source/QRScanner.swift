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
}

class QRScanner: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: QRScannerDelegate?
    private let serialQueue = DispatchQueue(label: "QRScanner serial queue")
    private var captureSession: AVCaptureSession?

    func start(success: @escaping (AVCaptureSession) -> Void, failure: @escaping (Error) -> Void) {
        serialQueue.async {
            do {
                let captureSession = try self.captureSession ?? QRScanner.createCaptureSessionWithDelegate(self)
                captureSession.startRunning()

                self.captureSession = captureSession
                DispatchQueue.main.async {
                    success(captureSession)
                }
            } catch {
                self.captureSession = nil
                DispatchQueue.main.async {
                    failure(error)
                }
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
        case noCaptureDevice
        case noQRCodeMetadataType
    }

    private class func createCaptureSessionWithDelegate(_ delegate: AVCaptureMetadataOutputObjectsDelegate) throws -> AVCaptureSession {
        let captureSession = AVCaptureSession()

        guard let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else {
            throw CaptureSessionError.noCaptureDevice
        }
        let captureInput = try AVCaptureDeviceInput(device: captureDevice)
        captureSession.addInput(captureInput)

        let captureOutput = AVCaptureMetadataOutput()
        // The output must be added to the session before it can be checked for metadata types
        captureSession.addOutput(captureOutput)
        guard let availableTypes = captureOutput.availableMetadataObjectTypes,
            (availableTypes as NSArray).contains(AVMetadataObjectTypeQRCode) else {
                throw CaptureSessionError.noQRCodeMetadataType
        }
        captureOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        captureOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)

        return captureSession
    }

    class var deviceCanScan: Bool {
        return (AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) != nil)
    }

    class var authorizationStatus: AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
    }

    class func requestAccess(_ completionHandler: @escaping (Bool) -> Void) {
        guard !CommandLine.isDemo else {
            return
        }
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: completionHandler)
    }

    // MARK: AVCaptureMetadataOutputObjectsDelegate

    func captureOutput(_ captureOutput: AVCaptureOutput?, didOutputMetadataObjects metadataObjects: [Any]?, from connection: AVCaptureConnection?) {
        guard let metadataObjects = metadataObjects else {
            return
        }

        for metadata in metadataObjects {
            if let metadata = metadata as? AVMetadataMachineReadableCodeObject,
                metadata.type == AVMetadataObjectTypeQRCode,
                let string = metadata.stringValue {
                    // Dispatch to the main queue because setMetadataObjectsDelegate doesn't
                    DispatchQueue.main.async {
                        self.delegate?.handleDecodedText(string)
                    }
            }
        }
    }
}
