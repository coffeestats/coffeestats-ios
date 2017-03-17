//
//  QRCodeScannerViewController.swift
//  Coffeestats
//
//  Created by Danilo Bürger on 16/03/2017.
//  Copyright © 2017 Danilo Bürger. All rights reserved.
//

import UIKit
import AVFoundation

protocol QRCodeScannerDelegate: class {
    func isAcceptable(_ qrCode: String) -> Bool
    func didScan(_ qrCode: String)
}

class QRCodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    weak var delegate: QRCodeScannerDelegate?

    private let previewLayer: AVCaptureVideoPreviewLayer

    private var stoppedCapture = false

    private let captureSession = AVCaptureSession()
    private let queue = DispatchQueue(label: "QRCodeScannerViewController queue")

    required init?(coder aDecoder: NSCoder) {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        super.init(coder: aDecoder)
        setup()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    convenience init() {
        self.init(nibName:nil, bundle:nil)
    }

    func setup() {
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer.backgroundColor = UIColor.black.cgColor
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        previewLayer.frame = view.layer.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.layer.addSublayer(previewLayer)

        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { (granted) in
            if granted {
                self.setupCaptureDevice()
            } else {
                // TODO(danilo): Handle error
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCapture()
    }

    private func setupCaptureDevice() {
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)

        let input = try? AVCaptureDeviceInput(device: captureDevice)
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        } else {
            // TODO(danilo): Handle error
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        } else {
            // TODO(danilo): Handle error
        }

        queue.async {
            self.captureSession.startRunning()
        }
    }

    private func stopCapture() {
        guard !stoppedCapture else { return }

        stoppedCapture = false
        previewLayer.connection.isEnabled = false

        queue.async {
            self.captureSession.stopRunning()
        }
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        guard !stoppedCapture else { return }
        guard let delegate = delegate else { return }
        guard metadataObjects != nil && metadataObjects.count > 0 else { return }

        if let metadata = metadataObjects[0] as? AVMetadataMachineReadableCodeObject,
            metadata.type == AVMetadataObjectTypeQRCode, metadata.stringValue != nil,
            delegate.isAcceptable(metadata.stringValue) {

            delegate.didScan(metadata.stringValue)
        }
    }

}
