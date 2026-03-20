//
//  PhotoPickerMoreItemView.swift
//  HXPhotoPicker
//
//  Created by user on 2026/3/19.
//  Copyright © 2026 Silence. All rights reserved.
//

import UIKit

public class PhotoPickerMoreItemView: UIView, PhotoNavigationItem {
    
    public weak var itemDelegate: PhotoNavigationItemDelegate?
    
    public var isSelected: Bool = false {
        didSet {
            button.isSelected = isSelected
        }
    }
    
    public var itemType: PhotoNavigationItemType { .more }
    
    let config: PickerConfiguration
    
    public required init(config: PickerConfiguration) {
        self.config = config
        super.init(frame: .zero)
        initView()
    }
    
    private var button: UIButton!
    
    private func initView() {
        button = UIButton(type: .custom)
        
        button.setImage(
            .imageResource.picker.photoList.moreNormal.image,
            for: .normal
        )
        
        button.addTarget(self, action: #selector(didMoreClick), for: .touchUpInside)
        
        addSubview(button)
        setColor()
    }
    
    private func setColor() {
        guard let color = PhotoManager.isDark ? config.navigationDarkTintColor : config.navigationTintColor else {
            return
        }
        button.imageView?.tintColor = color
    }
    
    @objc
    private func didMoreClick() {
        showMoreAlert()
    }
    
    private func showMoreAlert() {
        guard let targetView = self.findTargetViewController()?.view else {
            return
        }

        itemDelegate?.photoItem(self, didSelected: true)

    }
    
    private func findTargetViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let vc = current as? UIViewController {
                return vc
            }
            responder = current.next
        }
        return nil
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let fitSize = button.sizeThatFits(bounds.size)
        let buttonSize = CGSize(
            width: fitSize.width - 4,
            height: fitSize.height - 4
        )
        button.frame = CGRect(
            x: (bounds.width - buttonSize.width) / 2,
            y: (bounds.height - buttonSize.height) / 2,
            width: buttonSize.width,
            height: buttonSize.height
        )
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        button.sizeThatFits(size)
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                setColor()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
