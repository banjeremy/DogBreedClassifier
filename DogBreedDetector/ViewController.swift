//
//  ViewController.swift
//  DogBreedDetector
//
//  Created by Jeremy Jones on 12/26/17.
//  Copyright © 2017 Jeremy Jones. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
  
  let label: UILabel = {
    let label = UILabel()
    label.textColor = .white
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = "label"
    
    return label
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupCaptureSession()
    view.addSubview(label)
    setupLabel()
  }
  
  func setupCaptureSession() {
    let captureSession = AVCaptureSession()
    let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices
    
    do {
      if let captureDevice = availableDevices.first {
        let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
        captureSession.addInput(captureDeviceInput)
      }
    } catch {
      print(error.localizedDescription)
    }
    
    let captureOutput = AVCaptureVideoDataOutput()
    captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
    captureSession.addOutput(captureOutput)
    
    let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.frame = view.frame
    view.layer.addSublayer(previewLayer)
    
    captureSession.startRunning()
  }
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let model = try? VNCoreMLModel(for: DogBreedClassifier().model) else { return }
    let request = VNCoreMLRequest(model: model) { (finishedRequest, error) in
      guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }
      guard let observation = results.first else { return }
      
      DispatchQueue.main.async(execute: {
        self.label.text = observation.identifier
      })
    }
    
    guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
  }
  
  func setupLabel() {
    label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
  }
}

