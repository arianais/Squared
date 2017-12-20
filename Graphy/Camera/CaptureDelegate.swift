//
//  CaptureDelegate.swift
//  Graphy
//
//  Created by Ari on 12/19/17.
//  Copyright © 2017 Logical Nonsense LLC. All rights reserved.
//

import AVFoundation
import Photos

protocol CaptureDelegateType: class {}
@available(iOS 10.0, *)
@objc(CaptureDelegate)
class CaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, CaptureDelegateType {
    
    private(set) var requestedPhotoSettings: AVCapturePhotoSettings
    
    var willCapturePhotoAnimation: ()->Void
    var completed: (CaptureDelegate)->Void
    
    var jpegPhotoData: Data?
    var dngPhotoData: Data?
    
    init(requestedPhotoSettings: AVCapturePhotoSettings, willCapturePhotoAnimation: @escaping ()->Void, completed: @escaping (CaptureDelegate)->Void) {
        self.requestedPhotoSettings = requestedPhotoSettings
        self.willCapturePhotoAnimation = willCapturePhotoAnimation
        self.completed = completed
    }
    
    func didFinish() {
        self.completed(self)
    }
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        self.willCapturePhotoAnimation()
    }
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let error = error {
            NSLog("Error capturing photo: \(error)")
            return
        }
        
        self.jpegPhotoData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer!)
    }
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingRawPhoto rawSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let error = error {
            NSLog("Error capturing RAW photo: \(error)")
        }
        
        self.dngPhotoData = AVCapturePhotoOutput.dngPhotoDataRepresentation(forRawSampleBuffer: rawSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
    }
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            NSLog("Error capturing photo: \(error)")
            self.didFinish()
            return
        }
        
        if self.jpegPhotoData == nil && self.dngPhotoData == nil {
            NSLog("No photo data resource")
            self.didFinish()
            return
        }
        
        PHPhotoLibrary.requestAuthorization {status in
            if status == .authorized {
                
                var temporaryDNGFileURL: URL!
                if let dngPhotoData = self.dngPhotoData {
                    temporaryDNGFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(resolvedSettings.uniqueID).dng")
                    _ = try? dngPhotoData.write(to: temporaryDNGFileURL, options: .atomic)
                }
                
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    
                    if let jpegPhotoData = self.jpegPhotoData {
                        creationRequest.addResource(with: .photo, data: jpegPhotoData, options: nil)
                        
                        if let temporaryDNGFileURL = temporaryDNGFileURL {
                            let companionDNGResourceOptions = PHAssetResourceCreationOptions()
                            companionDNGResourceOptions.shouldMoveFile = true
                            creationRequest.addResource(with: .alternatePhoto, fileURL: temporaryDNGFileURL, options: companionDNGResourceOptions)
                        }
                    } else {
                        let dngResourceOptions = PHAssetResourceCreationOptions()
                        dngResourceOptions.shouldMoveFile = true
                        creationRequest.addResource(with: .photo, fileURL: temporaryDNGFileURL, options: dngResourceOptions)
                    }
                    
                }) {success, error in
                    if !success {
                        NSLog("Error occurred while saving photo to photo library: \(error!)")
                    }
                    
                    if
                        let temporaryDNGFileURL = temporaryDNGFileURL,
                        FileManager.default.fileExists(atPath: temporaryDNGFileURL.path)
                    {
                        _ = try? FileManager.default.removeItem(at: temporaryDNGFileURL)
                    }
                    
                    self.didFinish()
                }
            } else {
                NSLog("Not authorized to save photo")
                self.didFinish()
            }
        }
    }
    
}
