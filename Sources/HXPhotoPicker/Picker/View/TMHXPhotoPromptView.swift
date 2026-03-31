//
//  TMHXPhotoPromptView.swift
//  HXPhotoPicker
//
//  Created by user on 2026/1/6.
//  Copyright © 2026 Silence. All rights reserved.
//

import UIKit

class TMHXPhotoPromptView: UIView {

    public var promptStr: String = ""
    
    private let promptLabel: UILabel = {
        let label = UILabel()
        label.text = "Tmm can only access a limited number of authorized photos."
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(hexString: "#AEAEAE")
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    let manageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Manage", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        button.addTarget(self, action: #selector(manageButtonTapped), for: .touchUpInside)
        button.backgroundColor = UIColor(hexString: "#00D0DB")
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        return button
    }()
    
    private let line: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hexString: "#FFFFFF").withAlphaComponent(0.3)
        return view
    }()
    
    init(frame: CGRect,promptStr: String) {
        self.promptStr = promptStr
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder,promptStr: String) {
        self.promptStr = promptStr
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        backgroundColor = UIColor.black
        
        addSubview(promptLabel)
        addSubview(manageButton)
        addSubview(line)
        
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        manageButton.translatesAutoresizingMaskIntoConstraints = false
        line.translatesAutoresizingMaskIntoConstraints = false
        
        promptLabel.text = promptStr
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            self.heightAnchor.constraint(equalToConstant: 56),
            self.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            
            manageButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            manageButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),
            manageButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 86),
            manageButton.heightAnchor.constraint(equalToConstant: 32),
            
            promptLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            promptLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12),
            promptLabel.trailingAnchor.constraint(equalTo: manageButton.leadingAnchor, constant: -16),
            promptLabel.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: 8),
            promptLabel.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -8),
            
            line.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            line.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            line.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
            line.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }
    
    @objc private func manageButtonTapped() {
        
        onManageButtonTap?()
    }
    
    public var onManageButtonTap: (() -> Void)?

    public func setPromptText(_ text: String) {
        promptLabel.text = text
    }

    
}
