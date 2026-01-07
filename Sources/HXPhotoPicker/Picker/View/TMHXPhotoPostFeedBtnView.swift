//
//  TMHXPhotoPostFeedBtnView.swift
//  HXPhotoPicker
//
//  Created by user on 2026/1/6.
//  Copyright © 2026 Silence. All rights reserved.
//

import UIKit

class TMHXPhotoPostFeedBtnView: UIView {
    enum ButtonType: Int {
        case textRelease = 1
        case camera = 2
        case draft = 3
    }
    
    var onButtonTap: ((ButtonType) -> Void)?
    
    private lazy var textButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Text Release", for: .normal)
        button.setImage(UIImage(named: "pt_text_release"), for: .normal)
        button.tag = ButtonType.textRelease.rawValue
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .regular)
        button.setTitleColor(UIColor(hexString: "#F7F7F7").withAlphaComponent(0.85), for: .normal)
        button.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        button.backgroundColor = UIColor(hexString: "#FFFFFF").withAlphaComponent(0.1)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        setupButtonImageTopTitleBottom(button: button, spacing: 4)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var imageButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Camera", for: .normal)
        button.setImage(UIImage(named: "pt_camera"), for: .normal)
        button.tag = ButtonType.camera.rawValue
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .regular)
        button.setTitleColor(UIColor(hexString: "#F7F7F7").withAlphaComponent(0.85), for: .normal)
        button.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        button.backgroundColor = UIColor(hexString: "#FFFFFF").withAlphaComponent(0.1)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        setupButtonImageTopTitleBottom(button: button, spacing: 4)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var draftButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Draft", for: .normal)
        button.setImage(UIImage(named: "pt_draft"), for: .normal)
        button.tag = ButtonType.draft.rawValue
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .regular)
        button.setTitleColor(UIColor(hexString: "#F7F7F7").withAlphaComponent(0.85), for: .normal)
        button.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        button.backgroundColor = UIColor(hexString: "#FFFFFF").withAlphaComponent(0.1)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        setupButtonImageTopTitleBottom(button: button, spacing: 4)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        addSubview(textButton)
        addSubview(imageButton)
        addSubview(draftButton)
    }
    
    private func setupButtonImageTopTitleBottom(button: UIButton, spacing: CGFloat) {
        button.imageView?.contentMode = .center
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        

        let imageEdgeInsets = UIEdgeInsets(
            top: 12,
            left: 0,
            bottom: -32,
            right: 0
        )
        let titleEdgeInsets = UIEdgeInsets(
            top: 40,
            left: 0,
            bottom: -12,
            right: 0
        )
        
        button.imageEdgeInsets = imageEdgeInsets
        button.titleEdgeInsets = titleEdgeInsets
    }
    
    private func setupConstraints() {
        let screenScale = UIScreen.main.bounds.width / 390.0
        let buttonWidth = 114 * screenScale
        let buttonHeight: CGFloat = 68
        let buttonSpacing = 12 * screenScale
        let topOffset = 12.0
        
        NSLayoutConstraint.activate([
            textButton.topAnchor.constraint(equalTo: self.topAnchor, constant: topOffset),
            textButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            textButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            textButton.trailingAnchor.constraint(equalTo: imageButton.leadingAnchor, constant: -buttonSpacing),
            
            imageButton.topAnchor.constraint(equalTo: self.topAnchor, constant: topOffset),
            imageButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            imageButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            imageButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            
            draftButton.topAnchor.constraint(equalTo: self.topAnchor, constant: topOffset),
            draftButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            draftButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            draftButton.leadingAnchor.constraint(equalTo: imageButton.trailingAnchor, constant: buttonSpacing)
        ])
    }
    
    @objc private func buttonClicked(sender: UIButton) {
        guard let buttonType = ButtonType(rawValue: sender.tag) else { return }
        onButtonTap?(buttonType)
    }
}
