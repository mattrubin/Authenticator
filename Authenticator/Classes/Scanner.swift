//
//  Scanner.swift
//  Authenticator
//
//  Created by Matt Rubin on 11/7/15.
//  Copyright © 2015 Matt Rubin. All rights reserved.
//

import AVFoundation

class Scanner {
    class var deviceCanScan: Bool {
        return (AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) != nil)
    }
}
