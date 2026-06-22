//
//  GIFImageView.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2025/2/26.
//  Copyright © 2025 Silence. All rights reserved.
//

//#if canImport(SwiftyGif) && HXPICKER_ENABLE_CORE_IMAGEVIEW_GIF && HXPICKER_ENABLE_CORE
    import UIKit
//    import SwiftyGif

    public class GIFImageView: UIImageView, HXImageViewProtocol {
        private static let asyncDecodeThreshold = 5 * 1024 * 1024
        private static let decodeQueue = DispatchQueue(label: "com.hxphotopicker.gif.decode", qos: .userInitiated)
        private var imageDataIdentifier = UUID()
        
        public func setImageData(_ imageData: Data?) {
            setImageData(imageData, completionHandler: nil)
        }

        public func setImageData(_ imageData: Data?, completionHandler: (() -> Void)?) {
            imageDataIdentifier = UUID()
            let currentIdentifier = imageDataIdentifier
            guard let imageData else {
                clear()
                SwiftyGifManager.defaultManager.deleteImageView(self)
                image = nil
                completionHandler?()
                return
            }
            let decode: () -> UIImage? = {
                if let image = try? UIImage(gifData: imageData) {
                    return image
                }
                return .init(data: imageData)
            }
            let applyImage: (UIImage?) -> Void = { [weak self] decodedImage in
                guard let self, self.imageDataIdentifier == currentIdentifier else { return }
                if let decodedImage, decodedImage.imageData != nil {
                    self.setGifImage(decodedImage)
                }else {
                    self.image = decodedImage
                }
                completionHandler?()
            }
            if imageData.count >= Self.asyncDecodeThreshold {
                SwiftyGifManager.defaultManager.deleteImageView(self)
                Self.decodeQueue.async {
                    let decodedImage = decode()
                    DispatchQueue.main.async {
                        applyImage(decodedImage)
                    }
                }
                return
            }
            applyImage(decode())
        }
        
        public func _startAnimating() {
            startAnimatingGif()
        }
        
        public func _stopAnimating() {
            stopAnimatingGif()
        }
    }
//#endif
