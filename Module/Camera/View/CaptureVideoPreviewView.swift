//
//  CaptureVideoPreviewView.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 07.12.2021.
//

import Foundation
import UIKit
import AVFoundation.AVCaptureVideoPreviewLayer
import AVFoundation.AVCaptureSession

final class CaptureVideoPreviewView: UIView {
    
    required init(captureSession: AVCaptureSession, superView: UIView) {
        super.init(frame: .zero)
        videoPreviewLayer.session = captureSession
        videoPreviewLayer.videoGravity = .resizeAspectFill
        
        self.translatesAutoresizingMaskIntoConstraints = false
        superView.addSubview(self)
        self.topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
        self.leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
        self.trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    override static var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
