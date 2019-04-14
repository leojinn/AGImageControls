//
//  AGCameraViewController.swift
//  AGPosterSnap
//
//  Created by Michael Liptuga on 21.06.17.
//  Copyright © 2017 Agilie. All rights reserved.
//

import UIKit
import AVFoundation
import PhotosUI

protocol AGCameraViewControllerDelegate: class {
    
    func setFlashButtonHidden(_ hidden: Bool)
    func imageToLibrary()
    func cameraNotAvailable()
    
}

class AGCameraViewController: AGMainViewController {

    weak var delegate: AGCameraViewControllerDelegate?
    
    lazy var focusImageView: UIImageView = { [unowned self] in
        let imageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            imageView.image = AGAppResourcesService.getImage(self.configurator.cameraFocusIcon)
            imageView.backgroundColor = UIColor.clear
            imageView.alpha = 0
        
        return imageView
        }()
    
    lazy var phoneCamera : AGPhoneCamera =
        {
            let phoneCamera = AGPhoneCamera()
                phoneCamera.delegate = self
            return phoneCamera
    }()

    lazy var capturedImageView: UIView = { [unowned self] in
        let view = UIView.init(frame: self.view.bounds)
            view.backgroundColor = UIColor.black
            view.alpha = 0
        
        return view
        }()
    
    lazy var containerView: UIView = { [unowned self] in
        let view = UIView.init(frame: self.view.bounds)
            view.alpha = 0
        return view
    }()
    
    lazy var noCameraLabel: UILabel = { [unowned self] in
        let label = UILabel.init(frame: CGRect(x: 0, y: 0, width : 250, height : 26))
            label.font = self.configurator.noCameraFont
            label.textColor = self.configurator.noCameraColor
            label.text = self.configurator.noCameraTitle
            label.sizeToFit()
            label.center = CGPoint(x: self.view.center.x, y : self.view.center.y - 40)
        
        return label
        }()
    
    lazy var noCameraButton: UIButton = { [unowned self] in
        let button = UIButton.init(frame: CGRect(x: 0, y: 0, width : 250, height : 26))
            button.setTitle(self.configurator.settingsTitle, for: .normal)
            button.setTitleColor(self.configurator.settingsColor, for: .normal)
            button.titleLabel?.font = self.configurator.settingsFont
            button.sizeToFit()
            button.viewWithRadiusAndBorder(radius: 6, borderWidth: 1, borderColor: self.configurator.settingsColor)
            button.addTarget(self, action: #selector(settingsButtonDidTap), for: .touchUpInside)
            button.center = CGPoint(x: self.view.center.x, y: self.view.center.y + 20)

        return button
        }()
    
    lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(tapGestureRecognizerHandler(_:)))
        
        return gesture
        }()
    
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    var animationTimer: Timer?
    var startOnFrontCamera: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.view.backgroundColor = configurator.mainColor
        [containerView, focusImageView, capturedImageView].forEach {
            self.view.addSubview($0)
        }
        self.containerView.addSubview(blurView)
        self.view.addGestureRecognizer(tapGestureRecognizer)
        
        phoneCamera.setup(self.startOnFrontCamera)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer?.connection?.videoOrientation = .portrait
    }
}

extension AGCameraViewController
{
    func setupPreviewLayer() {
        let layer = AVCaptureVideoPreviewLayer(session: phoneCamera.session) 
        
        layer.backgroundColor = configurator.mainColor.cgColor
        layer.autoreverses = true
        layer.videoGravity = AVLayerVideoGravity(rawValue: convertFromAVLayerVideoGravity(AVLayerVideoGravity.resizeAspectFill))
        
        self.view.layer.insertSublayer(layer, at: 0)
        layer.frame = view.layer.frame
        self.view.clipsToBounds = true
        self.previewLayer = layer
    }
    
    // MARK: - Actions
    
    @objc func settingsButtonDidTap() {
        DispatchQueue.main.async {
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.openURL(settingsURL)
            }
        }
    }
    
    // MARK: - Camera actions
    
    func rotateCamera() {
        UIView.animate(withDuration: 0.3, animations: { 
            self.containerView.alpha = 1
        }, completion: { _ in
            self.phoneCamera.switchCamera {
                UIView.animate(withDuration: 0.7, animations: {
                    self.containerView.alpha = 0
                })
            }
        })
    }
    
    func flashCamera(_ title: String) {
        let mapping: [String: AVCaptureDevice.FlashMode] = [
            self.configurator.flashButtonOnTitle  : .on,
            self.configurator.flashButtonOffTitle : .off
        ]
        phoneCamera.flash(mapping[title] ?? .auto)
    }
    
    func takePicture() {
        guard let previewLayer = previewLayer else { return }
        
        UIView.animate(withDuration: 0.1, animations: {
            self.capturedImageView.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.capturedImageView.alpha = 0
            })
        })
        
        phoneCamera.takePhoto(previewLayer, location: nil) {
            self.delegate?.imageToLibrary()
        }
    }
    
    // MARK: - Timer methods
    
    @objc func timerDidFire() {
        UIView.animate(withDuration: 0.3, animations: { [unowned self] in
            self.focusImageView.alpha = 0
            }, completion: { _ in
                self.focusImageView.transform = CGAffineTransform.identity
        })
    }
    
    // MARK: - Camera methods
    
    func focusTo(_ point: CGPoint) {
        let convertedPoint = CGPoint(x: point.x / UIScreen.main.bounds.width,
                                     y: point.y / UIScreen.main.bounds.height)
        
        phoneCamera.focus(convertedPoint)
        
        focusImageView.center = point
        UIView.animate(withDuration: 0.245, animations: { 
            self.focusImageView.alpha = 1
            self.focusImageView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        }, completion: { _ in
            self.animationTimer = Timer.scheduledTimer(timeInterval: 1,
                                                       target: self,
                                                       selector: #selector(AGCameraViewController.timerDidFire),
                                                       userInfo: nil,
                                                       repeats: false)
        })
    }
    
    // MARK: - Tap
    
    @objc func tapGestureRecognizerHandler(_ gesture: UITapGestureRecognizer) {
        let touch = gesture.location(in: view)
        
        self.focusImageView.transform = CGAffineTransform.identity
        self.animationTimer?.invalidate()
        self.focusTo(touch)
    }
    
    // MARK: - Private helpers
    
    func showNoCamera(_ show: Bool) {
        [noCameraButton, noCameraLabel].forEach {
            show ? view.addSubview($0) : $0.removeFromSuperview()
        }
    }
}


extension AGCameraViewController : AGPhoneCameraDelegate
{
    func cameraNotAvailable(_ phoneCamera: AGPhoneCamera) {
        self.focusImageView.isHidden = true
        self.delegate?.cameraNotAvailable()
        self.showNoCamera(true)
    }

    func cameraDidStart(_ phoneCamera: AGPhoneCamera) {
        self.setupPreviewLayer()
    }

    func camera(_ phoneCamera: AGPhoneCamera, didChangeInput input: AVCaptureDeviceInput) {
        self.delegate?.setFlashButtonHidden(!input.device.hasFlash)
    }
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVLayerVideoGravity(_ input: AVLayerVideoGravity) -> String {
	return input.rawValue
}
