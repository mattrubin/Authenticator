//
//  Scanner.swift
//  Authenticator
//
//  Created by Matt Rubin on 11/7/15.
//  Copyright © 2015 Matt Rubin. All rights reserved.
//

import AVFoundation

@objc
protocol ScannerDelegate {
    func handleDecodedText(text: String)
}

class Scanner: NSObject {
    class var deviceCanScan: Bool {
        return (AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) != nil)
    }

    weak var delegate: ScannerDelegate?
    var captureSession: AVCaptureSession?

    func start() {
        captureSession?.startRunning()
    }

    func stop() {
        captureSession?.stopRunning()
    }

    func createCaptureSession() throws -> AVCaptureSession {
        let captureSession = AVCaptureSession()

        guard let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo),
            let captureInput = try? AVCaptureDeviceInput(device: captureDevice)
            else { throw CaptureSessionError.InputError }
        captureSession.addInput(captureInput)

        let captureOutput = AVCaptureMetadataOutput()
        // The output must be added to the session before it can be checked for metadata types
        captureSession.addOutput(captureOutput)
        guard let availableTypes = captureOutput.availableMetadataObjectTypes
            where (availableTypes as NSArray).containsObject(AVMetadataObjectTypeQRCode)
            else { throw CaptureSessionError.OutputError }
        captureOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        captureOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())

        return captureSession
    }

    enum CaptureSessionError: ErrorType {
        case InputError
        case OutputError
    }
}

extension Scanner: AVCaptureMetadataOutputObjectsDelegate {
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        guard let metadataObjects = metadataObjects
            else {return }

        for metadata in metadataObjects {
            if let metadata = metadata as? AVMetadataMachineReadableCodeObject
                where metadata.type == AVMetadataObjectTypeQRCode,
                let string = metadata.stringValue {
                    delegate?.handleDecodedText(string)
            }
        }
    }
}
