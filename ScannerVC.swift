//
//  ScannerVC.swift
//  OpenAssessments
//
//  Created by Alex DeCastro on 5/18/19.
//  Copyright © 2019 UCSD. All rights reserved.
//

import UIKit
import AVFoundation

protocol ChildVCDelegate:class {
    func childVCDidSave(_ controller: ScannerVC, text: String)
}

class ScannerVC: UIViewController {
    
    weak var delegate: ChildVCDelegate?
    
    @IBOutlet weak var messageLabel: UILabel!
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var barcodeFrameView: UIView?
    
    var foundBarcode: Bool!
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.upce,
                                      AVMetadataObject.ObjectType.code39,
                                      AVMetadataObject.ObjectType.code39Mod43,
                                      AVMetadataObject.ObjectType.code93,
                                      AVMetadataObject.ObjectType.code128,
                                      AVMetadataObject.ObjectType.ean8,
                                      AVMetadataObject.ObjectType.ean13,
                                      AVMetadataObject.ObjectType.aztec,
                                      AVMetadataObject.ObjectType.pdf417,
                                      AVMetadataObject.ObjectType.itf14,
                                      AVMetadataObject.ObjectType.dataMatrix,
                                      AVMetadataObject.ObjectType.interleaved2of5,
                                      AVMetadataObject.ObjectType.qr]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.foundBarcode = false
        
        // Do any additional setup after loading the view.
        
        // Get the back-facing camera for capturing videos.
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: AVMediaType.video,
            position: .back)
        
        // Get the camera device. Must attach a physical device.
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("ERROR: ScannerVC: viewDidLoad: Failed to get the camera device.")
            return
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Set the input device on the capture session.
            captureSession.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            
        } catch {
            // If any error occurs, print it out and don't continue any more.
            print(error)
            return
        }
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        // Start video capture.
        captureSession.startRunning()
        
        // Move the message label to the front.
        view.bringSubviewToFront(messageLabel)
        
        // Initialize barcode frame to highlight the barcode.
        barcodeFrameView = UIView()
        if let barcodeFrameView = barcodeFrameView {
            barcodeFrameView.layer.borderColor = UIColor.red.cgColor
            barcodeFrameView.layer.borderWidth = 4
            view.addSubview(barcodeFrameView)
            view.bringSubviewToFront(barcodeFrameView)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let connection =  videoPreviewLayer?.connection  {
            
            let currentDevice: UIDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation
            let previewLayerConnection : AVCaptureConnection = connection
            
            if previewLayerConnection.isVideoOrientationSupported {
                
                switch (orientation) {
                case .portrait:
                    updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                    
                case .landscapeRight:
                    updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                    break
                    
                case .landscapeLeft:
                    updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                    break
                    
                case .portraitUpsideDown:
                    updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
                    break
                    
                default:
                    updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                }
            }
        }
    }
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        layer.videoOrientation = orientation
        videoPreviewLayer?.frame = self.view.bounds
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    @IBAction func doneButton(_ sender: UIBarButtonItem) {
        self.delegate?.childVCDidSave(self, text: "return from done button")
        //assuming the delegate is assigned otherwise error
    }
    
    func processBarcode(barcodeString: String) {
        if presentedViewController != nil {
            return
        }
        let alertController = UIAlertController(
            title: "Scanned code",
            message: "\(barcodeString)",
            preferredStyle: .actionSheet)
        
        let confirmAction = UIAlertAction(
            title: "Confirm",
            style: UIAlertAction.Style.default,
            handler: {
                (action) -> Void in
                if (!self.foundBarcode) {
                    self.foundBarcode = true
                    self.captureSession.stopRunning()
                    self.videoPreviewLayer?.removeFromSuperlayer()
                    self.messageLabel.text = barcodeString
                    self.delegate?.childVCDidSave(self, text: barcodeString)
                }
        })
        
        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: UIAlertAction.Style.cancel,
            handler: { (action) -> Void in }
        )
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        alertController.popoverPresentationController?.sourceView = self.view
        
        present(alertController, animated: true, completion: {
        })
    }
}

extension ScannerVC: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if (foundBarcode) {
            return;
        }
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            barcodeFrameView?.frame = CGRect.zero
            messageLabel.text = "No barcode detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the barcode metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            barcodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                messageLabel.text = metadataObj.stringValue
                processBarcode(barcodeString: metadataObj.stringValue!)
            }
        }
    }
}

