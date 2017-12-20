//
//  PreviewView.swift
//  Graphy
//
//  Created by Ari on 12/19/17.
//  Copyright © 2017 Logical Nonsense LLC. All rights reserved.
//

import UIKit
import AVKit

@objc(PreviewView)
class PreviewView: UIView {

    override class var layerClass : AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var session: AVCaptureSession? {
        get {
            let previewLayer = self.layer as! AVCaptureVideoPreviewLayer
            return previewLayer.session
        }
        
        set {
            let previewLayer = self.layer as! AVCaptureVideoPreviewLayer
            previewLayer.session = newValue
        }
    }

}
