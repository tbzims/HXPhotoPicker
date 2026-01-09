//
//  EmptyView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

public class PhotoPickerEmptyView: UIView {
    private var titleLb: UILabel!
    private var subTitleLb: UILabel!
    private var emptyImgV: UIView!
    private var emptyBgV: UIView!
    
    let config: EmptyViewConfiguration
    init(config: EmptyViewConfiguration) {
        self.config = config
        super.init(frame: .zero)
        
        titleLb = UILabel()
        titleLb.text = config.titleStr
        titleLb.numberOfLines = 0
        titleLb.textAlignment = .center
        titleLb.font = .textPhotoList.emptyTitleFont
        addSubview(titleLb)
        
        subTitleLb = UILabel()
        subTitleLb.text = config.subStr
        subTitleLb.numberOfLines = 0
        subTitleLb.textAlignment = .center
        subTitleLb.font = .textPhotoList.emptySubTitleFont
        addSubview(subTitleLb)
        
//        emptyImgV = UIImageView()
//        emptyImgV.image =  UIImage(named: "TMHXBlack_No_data")
//        addSubview(emptyImgV)
        
        
        
        if let emptyLottieView = config.emptyLottieView {
            
//            emptyImgV = emptyLottieView
//            emptyImgV.frame = CGRect(x: 0, y: 0, width: 160, height: 120)
//            emptyImgV.centerX = centerX
//            emptyBgV.addSubview(emptyImgV)
            
            emptyBgV = emptyLottieView
            emptyBgV.backgroundColor = .clear
            addSubview(emptyBgV)
            
        }
        
        configColor()
    }
    
    private func configColor() {
        titleLb.textColor = PhotoManager.isDark ? config.titleDarkColor : config.titleColor
        subTitleLb.textColor = PhotoManager.isDark ? config.subTitleDarkColor : config.subTitleColor
        titleLb.font = config.titleFont
        subTitleLb.font = config.subTitleFont
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        emptyBgV.frame = CGRect(x: 0, y: 30, width: 160, height: 120)
        emptyBgV.centerX = centerX
//        emptyImgV.frame = CGRect(x: 0, y: 30, width: 160, height: 120)
//        emptyImgV.centerX = centerX
        if let titleHeight = titleLb.text?.height(ofFont: titleLb.font, maxWidth: width - 20) {
            titleLb.frame = CGRect(x: 10, y: CGRectGetMaxY(emptyBgV.frame) + 12, width: width - 20, height: titleHeight)
        }
        if let subTitleHeight = subTitleLb.text?.height(ofFont: subTitleLb.font, maxWidth: width - 20) {
            subTitleLb.frame = CGRect(x: 10, y: titleLb.frame.maxY + 8, width: width - 20, height: subTitleHeight)
        }
        height = subTitleLb.frame.maxY
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configColor()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
