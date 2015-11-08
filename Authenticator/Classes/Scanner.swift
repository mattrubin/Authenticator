//
//  Scanner.swift
//  Authenticator
//
//  Created by Matt Rubin on 11/7/15.
//  Copyright © 2015 Matt Rubin. All rights reserved.
//

import AVFoundation

class Scanner: NSObject {
    class var deviceCanScan: Bool {
        return (AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) != nil)
    }

    class func createCaptureSession() throws -> AVCaptureSession {
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

        return captureSession
    }

    enum CaptureSessionError: ErrorType {
        case InputError
        case OutputError
    }
}
